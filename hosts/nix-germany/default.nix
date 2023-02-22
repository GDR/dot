{ inputs, lib, config, pkgs, home-manager, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
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
      git.enable    = true;
      zsh.enable    = true;
      neovim.enable = true;
      common.enable = true;
      ssh.enable    = true;
    };

    secure = {
      wireguard.enable = true;
    };

    virtualization = {
      docker.enable = true;
    };

    development = {
      common.enable = true;
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
      };
      terminal = {
        kitty.enable      = true;
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

  system.stateVersion = "22.11";
}
