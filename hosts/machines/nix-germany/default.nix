{ inputs, lib, config, pkgs, home-manager, hardware, ... }: {

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports = [
    hardware.nixosModules.lenovo-thinkpad-t480
    ./hardware-configuration.nix
  ];

  networking.hostName = "nix-germany";
  networking.networkmanager.enable = true;

  programs.nm-applet.enable = true;

  modules = {
    common = {
      browsers = {
        chrome.enable = true;
      };
      shell = {
        git.enable = true;
        tmux.enable = true;
        utils.enable = true;
        ssh.enable = true;
        ssh.server.enable = true;
        zsh.enable = true;
      };
      editors = {
        neovim.enable = true;
        vscode.enable = true;
        vscode-server.enable = true;
      };
      terminal = {
        kitty.enable = true;
      };
      utils = {
        keepassxc.enable = true;
      };
      messenger = { };
      virtualisation = {
        podman.enable = true;
      };
    };
    linux = {
      awesomewm.enable = true;
      sound.enable = true;
    };
    fonts.enable = true;
  };

  time.timeZone = "Europe/Moscow";

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  system.stateVersion = "24.11";

  # System-scope modules
  systemLinux = {
    graphics.intel = {
      enable = true;
      enableHybridCodec = true;
      tearFree = true;
    };
    powerManagement = {
      enable = true;
      tlp = true;
      upower = true;
      lidSwitch = "ignore";
    };
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 53 80 443 8080 8001 8081 ];
      allowedUDPPorts = [ 53 80 443 8080 8001 8081 ];
    };
  };
}
