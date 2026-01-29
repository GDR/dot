{ inputs, lib, config, pkgs, home-manager, hardware, ... }:
let
  # Import user defaults by name
  importUser = name: import ../_users/${name}.nix { inherit lib; };
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  # Enable user via hostUsers (new system)
  # Defaults from hosts/_users/<name>.nix, host-specific overrides here
  hostUsers.dgarifullin = importUser "dgarifullin" // {
    enable = true;
    # Host-specific: SSH key for this machine
    keys = [{
      name = "goldstar";
      type = "rsa";
      purpose = [ "git" "ssh" ];
      isDefault = true;
    }];
    # Per-user tags (enables user-scope modules for this user)
    tags.enable = [
      "browsers"
      "core"
      "editors-terminal"
      "editors-ui"
      "games"
      "media"
      "shells"
      "terminal"
    ];
  };

  networking.hostName = "nix-goldstar";

  # System-scope modules (top-level, not in modules.*)
  systemAll = {
    fonts.enable = true;
    nix-settings.enable = true;
    nix-gc.enable = true;
    shell = {
      ssh.enable = true;
      git.enable = true;
    };
  };

  systemLinux = {
    networking = {
      networkmanager.enable = true;
      tailscale.enable = true;
    };
    graphics.nvidia = {
      enable = true;
      open = true;
    };
    keyboards.keychron.enable = true;
    sound.enable = true;
  };

  modules = {
    # Global tags removed - using per-user tags instead (hostUsers.*.tags)
    common = {
      # zsh moved to modules_v2 with "shells" tag
      # cursor moved to modules_v2 with "editors-ui" tag
      # neovim moved to modules_v2 with "editors-terminal" tag
      utils = {
        # bitwarden.enable = true;
        keepassxc.enable = true;
        qbittorrent.enable = true;
      };
    };
    linux = {
      hyprland.enable = true;
      # sound moved to systemLinux.sound
      # keychron moved to systemLinux.keyboards.keychron
      # steam moved to modules_v2 with "games" tag
    };
    # fonts moved to systemAll.fonts
  };

  time.timeZone = "Europe/Moscow";
}
