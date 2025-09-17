{ inputs, lib, config, pkgs, home-manager, hardware, ... }: {

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports = [
    ./hardware-configuration.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = false;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.gfxmodeEfi = "1280x1024x32,auto";
  boot.loader.grub.extraEntries = ''
    menuentry "Windows Boot Manager (on /dev/nvme0n1p1)" {
      insmod part_gpt
      insmod fat
      search --no-floppy --fs-uuid --set=root A4F4-C19F
      chainloader /efi/Microsoft/Boot/bootmgfw.efi
    }
  '';

  # Enable Bluetooth firmware and kernel modules
  hardware.enableRedistributableFirmware = true;
  boot.extraModulePackages = with config.boot.kernelPackages; [
    # Add any additional modules if needed
  ];
  boot.kernelModules = [ "btusb" "btmtk" "mt7925_common" ];

  # Enable MediaTek MT7925 Bluetooth support
  boot.blacklistedKernelModules = [ ]; # Ensure no blocking modules
  hardware.firmware = with pkgs; [
    linux-firmware
  ];

  # Additional kernel parameters for MT7925
  boot.kernelParams = [ "btusb.enable_autosuspend=0" ];

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

  # Add user to bluetooth group for D-Bus access
  users.users.dgarifullin.extraGroups = [ "bluetooth" "dialout" ];

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
        idea.enable = true;
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
      awesomewm.enable = false;
      hyprland.enable = true;
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

    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          DiscoverableTimeout = 0;
          Experimental = true;
        };
      };
    };
  };
  services.blueman.enable = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  home.programs.git.extraConfig.user = {
    signingkey = "/home/dgarifullin/.ssh/goldstar_id_rsa.pub";
  };

  security-keys.signingkey = "/home/dgarifullin/.ssh/goldstar_id_rsa";

  # Override fcitx5 package to fix Home Manager evaluation error
  home-manager.users.dgarifullin.i18n.inputMethod = {
    enabled = null;
    fcitx5.fcitx5-with-addons = pkgs.kdePackages.fcitx5-with-addons;
  };

  system.stateVersion = "25.05";
}
