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
      "media" 
    ];
  };

  networking.hostName = "nix-goldstar";

  # System-scope modules (top-level, not in modules.*)
  systemAll = {
    nix-settings.enable = true;
    nix-gc.enable = true;
    shell.ssh.enable = true;
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
  };

  modules = {
    # Global tags removed - using per-user tags instead (hostUsers.*.tags)
    common = {
      browsers = {
        # chrome.enable = true;
        firefox.enable = true;
      };
      shell = {
        git = {
          enable = true;
          userName = "Damir Garifullin";
          userEmail = "gosugdr@gmail.com";
          signingKey = "/home/dgarifullin/.ssh/goldstar_id_rsa.pub";
        };
        zsh.enable = true;
      };
      editors = {
        neovim.enable = true;
        cursor.enable = true;
      };
      terminal = {
        ghostty.enable = true;
      };
      utils = {
        # bitwarden.enable = true;
        keepassxc.enable = true;
        qbittorrent.enable = true;
      };
      vpn = {
        # vless.enable = true; 
      };
    };
    linux = {
      hyprland.enable = true;
      sound.enable = true;
      utils = {
        keychron.enable = true;
      };

      games = {
        steam.enable = true;
        steam.enableGamescope = true;
        steam.remotePlayOpenFirewall = true;
        steam.dedicatedServerOpenFirewall = true;

        lutris.enable = true;
        lutris.enableGamescope = true;
      };
    };
    fonts.enable = true;
  };

  time.timeZone = "Europe/Moscow";
}