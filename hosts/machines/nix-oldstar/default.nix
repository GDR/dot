{ inputs, lib, config, pkgs, home-manager, hardware, ... }:
let
  # Import user defaults by name
  importUser = name: import ../../users/${name}.nix { inherit lib; };
in
{
  imports = [
    hardware.nixosModules.lenovo-thinkpad-t480
    ./hardware-configuration.nix

    # ── Vantage infra modules (consul + nomad) ──
    inputs.vantage.nixosModules.infra-server # consul + nomad server+client
    inputs.vantage.nixosModules.consul-dns # *.consul DNS forwarding via systemd-resolved

    # ── Vantage remote-builder module ──
    # Sets trusted-users, max-jobs = "auto", and system-features (kvm, big-parallel)
    inputs.vantage.nixosModules.remote-builder
  ];

  networking.hostName = "nix-oldstar";
  environment.variables.DOTFILES_DIR = "/home/dgarifullin/Workspaces/gdr/dot";

  # Enable user via hostUsers (system user account only, no home modules)
  hostUsers.dgarifullin = importUser "dgarifullin" // {
    enable = true;
    # Host-specific: SSH key for this machine
    keys = [{
      name = "oldstar";
      type = "ed25519";
      purpose = [ "git" "ssh" ];
      isDefault = true;
    }];
    # SSH configuration
    ssh = [
      {
        host = "*";
        identityFile = "~/.ssh/oldstar_id_ed25519";
        extraOptions.AddKeysToAgent = "yes";
      }
      {
        host = "github.com";
        user = "git";
        identityFile = "~/.ssh/oldstar_id_ed25519";
      }
      {
        host = "nix-oldstar";
        forwardAgent = true;
      }
      {
        host = "nix-goldstar";
        forwardAgent = true;
      }
    ];
    # Minimal home modules - CLI tools and shell
    modules = {
      home.cli.enable = true;
      home.shell.zsh.enable = true;
      home.editors.neovim.enable = true;
      home.shell.ssh.enable = true;
      home.shell.tmux.enable = true;
      home.virtualisation.docker.enable = true;
    };
    # deploy-rs (and any other automation) can sudo without a password
    sudo.nopasswd = true;
  };

  time.timeZone = "Europe/Moscow";

  # System-scope modules (server-side only)
  systemAll = {
    fonts.enable = true;
    nix.settings.enable = true;
    nix.gc.enable = true;
    sops.enable = true;
    shell = {
      ssh.enable = true;
      git.enable = true;
    };
  };

  systemLinux = {
    networking = {
      networkmanager.enable = true;
      openssh = {
        enable = true; # SSH server + charon-key AuthorizedKeysCommand
        userMap = { "dgarifullin" = "gdr"; }; # NixOS user -> GitHub username for charon-key
      };
      tailscale.enable = true;
    };
    editors.vscode-server.enable = true;
    graphics.intel = {
      enable = true;
      enableHybridCodec = true;
      tearFree = true;
    };
    power-management = {
      enable = true;
      tlp = true;
      upower = true;
      lidSwitch = "ignore";
    };
    networking.firewall = {
      enable = true;
      # Vault API (8200) and Raft (8201) exposed on Tailscale
      allowedTCPPorts = [ 22 53 80 443 8080 8001 8081 8200 8201 ];
      allowedUDPPorts = [ 22 53 80 443 8080 8001 8081 ];
    };
    sound.enable = true;
  };

  # ── Consul: single-node homelab server ─────────────────────────────
  services.vantage.consul = {
    enable = true;
    mode = "both"; # server + client on one node
    datacenter = "homelab";
    enableUi = true; # UI at http://<tailscale-ip>:8500
    # Uncomment after gossip key is provisioned in vantage/secrets/shared/cluster.yaml:
    # gossipKeyFile = config.sops.secrets.consul_gossip_key.path;
  };

  # ── Nomad: server + client on homelab ──────────────────────────────
  services.vantage.nomad = {
    enable = true;
    server = true;
    client = true;
    datacenter = "homelab";
    # gossipKeyFile = config.sops.secrets.nomad_gossip_key.path;
    # Point Nomad at the local Vault instance
    vaultAddr = "http://127.0.0.1:8200";
  };

  # ── Consul DNS: *.consul forwarding via local Consul agent ────────────
  # Uses local Consul agent (127.0.0.1:8600 default)
  services.vantage.consul-dns.enable = true;

  # ── Vault: Raft-backed, Tailscale-bound, GCP KMS auto-unseal ────────────────
  # Auto-unseal via GCP Cloud KMS — no unseal keys stored anywhere.
  # Vault calls GCP KMS API on every startup to decrypt its root key.
  #
  # First-boot ordering:
  #   1. Provision GCP KMS resources (infra/terraform/providers/gcp/)
  #      and place the SA key in secrets/gcp-vault-sa (sops)
  #   2. Deploy this config → vault starts and auto-unseals via GCP KMS ✅
  #   3. Run `just vault-init` (VAULT_ADDR=http://nix-oldstar:8200)
  #      to initialize Vault (one-time — generates root token)
  #   4. Run `just tf-apply` → writes policies + Nomad token
  #   5. Run `just vault-seal-secrets` → encrypts Nomad token into sops
  services.vantage.vault = {
    enable = true;
    clusterAddr = "nix-oldstar"; # Tailscale MagicDNS hostname
    gcpKms.enable = false;
  };

  # ── sops secrets ───────────────────────────────────────────────────
  # gcp-vault-sa: GCP service account key JSON for Vault KMS auto-unseal.
  # Generated by: infra/terraform/providers/gcp/ → output: vault_sa_key_json
  # Encrypted with: sops (age key for nix-oldstar from .sops.yaml)
  sops.secrets."gcp-vault-sa" = {
    sopsFile = ./secrets/gcp-vault-sa;
    format = "binary"; # raw JSON file, not YAML/JSON envelope
    owner = "vault";
    mode = "0400";
  };

  # # nomad-vault-token-env: VAULT_TOKEN=<nomad-cluster-token>
  # # Created by: just vault-seal-secrets (reads terraform output)
  # sops.secrets."nomad-vault-token-env" = {
  #   sopsFile = ./secrets/nomad-vault-token-env;
  #   format = "binary"; # raw encrypted file, not YAML/JSON
  #   owner = "root";
  #   mode = "0400";
  # };

  # # Inject VAULT_TOKEN into the Nomad systemd service
  # systemd.services.nomad.serviceConfig.EnvironmentFile =
  #   config.sops.secrets."nomad-vault-token-env".path;

  # ── Tailscale: connect manually with `tailscale up` ─────────────────
  # Run: sudo tailscale up --auth-key=<key>
}
