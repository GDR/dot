{ inputs, lib, config, pkgs, home-manager, hardware, ... }: {

  # Enable user via hostUsers (new system)
  hostUsers.dgarifullin = {
    enable = true;
    fullName = "Damir Garifullin";
    email = "gosugdr@gmail.com";
    github = "gdr";
    extraGroups = [ "wheel" "audio" "libvirtd" "input" ];
    keys = [{
      name = "goldstar";
      type = "rsa";
      purpose = "both";
      isDefault = true;
    }];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports = [
    ./hardware-configuration.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nix-goldstar";
  networking.networkmanager.enable = true;

  programs.nm-applet.enable = true;

  # X11 configuration for NVIDIA
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  modules = {
    tags = {
      enable = [ 
        "core" 
        "media" 
      ];
    };
    common = {
      browsers = {
        chrome.enable = true;
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
        ssh.enable = true;
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
        tailscale.enable = true;
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

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };


  security-keys.signingkey = "/home/dgarifullin/.ssh/goldstar_id_rsa";

  system.stateVersion = "25.11";
}
