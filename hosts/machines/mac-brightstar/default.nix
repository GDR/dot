{ self, inputs, pkgs, lib, overlays, ... }:
let
  # Import user defaults by name
  importUser = name: import ../../users/${name}.nix { inherit lib; };
in
{
  imports = [
    inputs.vantage.darwinModules.consul-dns # *.consul DNS via /etc/resolver/consul
  ];

  nix.enable = true;

  # Fix GID mismatch for existing Nix installation
  ids.gids.nixbld = 30000;


  # Enable user via hostUsers (new system)
  # Defaults from hosts/users/<name>.nix, host-specific overrides here
  hostUsers.dgarifullin = importUser "dgarifullin" // {
    enable = true;
    # Host-specific: SSH key for this machine
    keys = [{
      name = "brightstar";
      type = "ed25519";
      purpose = [ "git" "ssh" ];
      isDefault = true;
    }];
    # SSH configuration
    ssh = [
      {
        host = "*";
        identityFile = "~/.ssh/brightstar_id_ed25519";
        extraOptions.AddKeysToAgent = "yes"; # Darwin: use Touch ID prompt each time
      }
      {
        host = "github.com";
        user = "git";
        identityFile = "~/.ssh/brightstar_id_ed25519";
      }
    ];
    # Hierarchical module enables
    modules = {
      home.ai-tools.enable = true;
      home.browsers.enable = true;
      home.cli.enable = true;
      home.desktop.enable = true; # was desktop-utils
      home.downloads.enable = true;
      home.editors.enable = true;
      home.messengers.enable = true;
      home.security.enable = true;
      home.shell.enable = true;
      home.terminal.enable = true;
      home.utils.raycast.enable = true;
      home.virtualisation.docker.enable = true;
    };
  };

  networking.hostName = "mac-brightstar";

  # ── Remote builder: nix-oldstar (x86_64-linux) ─────────────────────
  # Offloads x86_64-linux builds (e.g. Vantage infra-image-test qcow2) to nix-oldstar.
  # nix-oldstar imports vantage.nixosModules.remote-builder (trusted-users, kvm, max-jobs).
  nix.distributedBuilds = true;

  nix.buildMachines = [
    {
      hostName = "nix-oldstar"; # Tailscale MagicDNS — must be reachable
      system = "x86_64-linux";
      protocol = "ssh-ng";
      maxJobs = 8;
      speedFactor = 2;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    }
  ];

  # System-scope modules (top-level, not in modules.*)
  systemAll = {
    # fonts.enable = true;
    nix.settings.enable = true;
    nix.gc.enable = true;
    sops.enable = true;
    shell = {
      ssh.enable = true;
      git.enable = true;
    };
  };

  # Darwin-specific system modules
  systemDarwin = {
    macos-settings.enable = true;
    homebrew = {
      enable = true;
      user = "dgarifullin";
    };
    app-aliases.enable = true; # Spotlight aliases for home-manager apps
    openssh = {
      enable = true;
      userMap = { "dgarifullin" = "gdr"; };
    };
  };

  time.timeZone = "Europe/Moscow";

  # *.consul DNS forwarding — queries nix-oldstar's Consul over Tailscale
  services.vantage.consul-dns = {
    enable = true;
    nameserver = "100.64.100.3"; # nix-oldstar Tailscale IP
  };
}
