{ inputs, lib, config, pkgs, home-manager, hardware, ... }: {

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
    common = {
      browsers = {
        firefox.enable = true;
      };
      shell = {
        git.enable = true;
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
        bitwarden.enable = true;
        keepassxc.enable = true;
        qbittorrent.enable = true;
      };
      vpn = {
        tailscale.enable = true;
      };
    };
    linux = {
      hyprland.enable = true;
      sound.enable = true;
      utils = {
        systemd-resolved.enable = true;
        keychron.enable = true;
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

  home.programs.git.extraConfig.user = {
    signingkey = "/home/dgarifullin/.ssh/goldstar_id_rsa.pub";
  };

  system.stateVersion = "25.05";
}
