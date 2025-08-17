{ inputs, lib, config, pkgs, home-manager, hardware, ... }: {

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports = [
    ./hardware-configuration.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.gfxmodeEfi = "1280x1024x32,auto";

  networking.hostName = "nix-goldstar";
  networking.networkmanager.enable = true;

  programs.nm-applet.enable = true;

  # X11 configuration for NVIDIA to prevent tearing
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.deviceSection = ''
    Option "TearFree" "true"
    Option "TripleBuffer" "true"
    Option "UseEvents" "false"
  '';

  modules = {
    common = {
      browsers = {
        firefox.enable = true;
        chrome.enable = true;
      };
      shell = {
        git.enable = true;
        ssh.enable = true;
        tmux.enable = true;
        utils.enable = true;
        zsh.enable = true;
      };
      editors = {
        neovim.enable = true;
        vscode.enable = true;
        cursor.enable = true;
      };
      terminal = {
        kitty.enable = true;
        ghostty.enable = true;
      };
      utils = {
        bitwarden.enable = true;
        keepassxc.enable = true;
        ollama.enable = true;
        lmstudio.enable = true;
      };
      vpn = {
        tailscale.enable = true;
      };
    };
    linux = {
      awesomewm.enable = true;
      sound.enable = true;
      utils = {
        systemd-resolved.enable = true;
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

  home.programs.git.extraConfig.user = {
    signingkey = "/home/dgarifullin/.ssh/goldstar_id_rsa.pub";
  };

  security-keys.signingkey = "/home/dgarifullin/.ssh/goldstar_id_rsa";


  system.stateVersion = "25.05";
}
