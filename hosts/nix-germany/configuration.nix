# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{ inputs, lib, config, pkgs, home-manager, ... }: {

  # Configure nix and nixpkgs
  environment.variables.NIXPKGS_ALLOW_UNFREE = "1";
  nixpkgs.config.allowUnfree = true;
  
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.hardware.nixosModules.lenovo-thinkpad-t480

    ./hardware-configuration.nix
  ];

  networking.hostName = "Nix-Germany";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Moscow";

  modules = {
    shell = {
      git.enable    = true;
      zsh.enable    = true;
      neovim.enable = true;
      htop.enable   = true;
      exa.enable   = true;
      ssh.enable   = true;
      tmux.enable   = true;

      xbacklight.enable = true;
      acpi.enable = true;
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
      };
      browsers = {
        chrome.enable = true;
      };
      terminal = {
        alacritty.enable  = true;
        kitty.enable      = true;
      };
      development = {
        vscode.enable = true;
      };

      awesomewm.enable  = true;
      touchpad.enable   = true;
      ru-layout.enable  = true;
      sound.enable      = true;
    };
  };

  system.stateVersion = "22.11";
}
