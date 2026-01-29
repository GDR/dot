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
      "desktop-utils"
      "desktop-utils-wayland"
      "downloads"
      "editors-terminal"
      "editors-ui"
      "games"
      "media"
      "security"
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
    desktop.hyprland.enable = true;
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

  time.timeZone = "Europe/Moscow";
}
