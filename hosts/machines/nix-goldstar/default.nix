{ inputs, lib, config, pkgs, home-manager, hardware, ... }:
let
  # Import user defaults by name
  importUser = name: import ../../users/${name}.nix { inherit lib; };
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  # Enable user via hostUsers (new system)
  # Defaults from hosts/users/<name>.nix, host-specific overrides here
  hostUsers.dgarifullin = importUser "dgarifullin" // {
    enable = true;
    # Host-specific: SSH key for this machine
    keys = [{
      name = "goldstar";
      type = "rsa";
      purpose = [ "git" "ssh" ];
      isDefault = true;
    }];
    # Hierarchical module enables
    modules = {
      home.browsers.enable = true;
      home.cli.enable = true;
      home.desktop.enable = true;
      home.downloads.enable = true;
      home.editors.enable = true;
      home.games.enable = true;
      home.media.enable = true;
      home.messengers.enable = true;
      home.security.enable = true;
      home.shell.enable = true;
      home.terminal.enable = true;
      home.virtualisation.enable = true;
    };
  };

  networking.hostName = "nix-goldstar";

  # System-scope modules (top-level, not in modules.*)
  systemAll = {
    fonts.enable = true;
    nix.settings.enable = true;
    nix.gc.enable = true;
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
    # keyboards.keychron.enable = true;
    sound.enable = true;
  };

  time.timeZone = "Europe/Moscow";
}
