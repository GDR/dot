{ inputs, outputs, lib, config, pkgs, home-manager, ... }: {
  
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
    ];
  };

  imports = [
    inputs.hardware.nixosModules.lenovo-thinkpad-t480
    ./hardware-configuration.nix
  ];

  services.xserver.videoDrivers = ["intel"];
  services.xserver.deviceSection = ''
    Option "TearFree" "true"
  '';

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  networking.hostName = "Nix-Germany";
  networking.networkmanager.enable = true;

  programs.nm-applet.enable = true;

  time.timeZone = "Europe/Moscow";

  modules = {
    shell = {
      acpi.enable   = true;
      fd.enable     = true;
      git.enable    = true;
      zsh.enable    = true;
      neovim.enable = true;
      common.enable = true;
      ssh.enable    = true;
      xclip.enable  = true;
      unarchive.enable = true;
    };

    secure = {
      wireguard.enable = true;
    };

    virtualization = {
      docker.enable = true;
    };

    development = {
      common.enable = true;
      direnv.enable = true;
    };

    desktop = {
      apps = {
        keepass.enable      = true;
        telegram.enable     = true;
        vlc.enable          = true;
        qbittorrent.enable  = true;
        steam.enable        = true;
        zoom.enable         = true;
      };
      browsers = {
        chrome.enable = true;
        edge.enable = true;
      };
      terminal = {
        kitty.enable        = true;
      };
      development = {
        vscode.enable = true;
        gcc.enable = true;
      };

      awesomewm.enable  = true;
      touchpad.enable   = true;
      ru-layout.enable  = true;
      sound.enable      = true;
      fonts.enable      = true;
    };
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        libvdpau-va-gl
        vaapiVdpau
      ];
    };
  };

  # For thinkpad
  services.tlp.enable = true;

  # Battery power management
  services.upower.enable = true;

  system.stateVersion = "22.11";
}
