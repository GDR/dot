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
      home.desktop = {
        # Desktop utilities (appearance, services, widgets)
        appearance.enable = true;
        services.enable = true;
        widgets.enable = true;
        utils.enable = true;
        # Window manager (pick one)
        hyprland.enable = true;
        # awesomewm.enable = true;
      };
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
    networking = {
      networkmanager.enable = true;
      openssh = {
        enable = true; # SSH server + charon-key AuthorizedKeysCommand
        userMap = { "*" = "gdr"; }; # NixOS user -> GitHub username for charon-key
      };
      tailscale.enable = true;
    };
    graphics.nvidia = {
      enable = true;
      open = true;
    };
    sound.enable = true;
  };

  time.timeZone = "Europe/Moscow";
}
