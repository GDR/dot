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
  # boot.loader.grub.useOSProber = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.gfxmodeEfi = "1280x1024x32,auto";

  networking.hostName = "nix-goldstar";
  networking.networkmanager.enable = true;

  programs.nm-applet.enable = true;

  # X11 configuration for NVIDIA
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  # NVIDIA performance options
  services.xserver.deviceSection = ''
    Option "TearFree" "true"
    Option "TripleBuffer" "true"
    Option "UseEvents" "false"
  '';

  # Monitor configuration using systemd service to run after X11 starts
  systemd.services.configure-displays = {
    description = "Configure dual monitor setup";
    after = [ "display-manager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.xorg.xrandr}/bin/xrandr --output DP-2  --pos 0x2160 --mode 3840x2160 --rate 170.00 --primary --output DP-0 --mode 3840x2160 --rate 60.00  --pos 0x0";
      Environment = "DISPLAY=:0";
      User = "dgarifullin";
    };
  };

  # Alternative: Use xrandrHeads as fallback
  services.xserver.xrandrHeads = [
    {
      output = "DP-2";
      primary = true;
      monitorConfig = ''
        Option "PreferredMode" "3840x2160"
        Option "Position" "0 2160"
      '';
    }
    {
      output = "DP-0";
      monitorConfig = ''
        Option "PreferredMode" "3840x2160"
        Option "Position" "0 0"
      '';
    }
  ];

  # Additional X11 configuration
  services.xserver.autoRepeatDelay = 200;
  services.xserver.autoRepeatInterval = 30;

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
        lmstudio.enable = true;
        ollama.enable = true;
        qbittorrent.enable = true;
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
