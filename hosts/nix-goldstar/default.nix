{ inputs, lib, config, pkgs, home-manager, hardware, ... }:
let
  # Import user defaults by name
  importUser = name: import ../_users/${name}.nix { inherit lib; };
in
{
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
    tags.enable = [ "browsers" "core" "media" ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports = [
    ./hardware-configuration.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nix-goldstar";

  # System-scope modules (top-level, not in modules.*)
  systemAll = {
    shell.ssh.enable = true;
    nix-gc.enable = true;
  };
  
  systemLinux.networking = {
    networkmanager.enable = true;
    tailscale.enable = true;
  };

  # X11 configuration for NVIDIA
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

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

  hardware = {
    graphics.enable = true;

    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      # Force full composition pipeline to prevent tearing
      forceFullCompositionPipeline = true;
    };
  };

  system.stateVersion = "25.11";
}
