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
  environment.variables.DOTFILES_DIR = "/home/dgarifullin/Workspaces/gdr/nix-dots";

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
      allowedTCPPorts = [ 22 53 80 443 8080 8001 8081 ];
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
  };

  # ── Consul DNS: *.consul forwarding via local Consul agent ────────────
  # Uses local Consul agent (127.0.0.1:8600 default)
  services.vantage.consul-dns.enable = true;

  # ── Tailscale: connect manually with `tailscale up` ─────────────────
  # Run: sudo tailscale up --auth-key=<key>
}
