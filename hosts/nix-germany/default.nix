{ inputs, lib, config, pkgs, home-manager, hardware, ... }: {

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports = [
    hardware.nixosModules.lenovo-thinkpad-t480
    ./hardware-configuration.nix
  ];

  services.xserver.videoDrivers = [ "intel" ];
  services.xserver.deviceSection = ''
    Option "TearFree" "true"
  '';

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

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
        kubernetes.enable = true;
      };
    };
    linux = {
      awesomewm.enable = true;
      sound.enable = true;
    };
    fonts.enable = true;
  };

  time.timeZone = "Europe/Moscow";

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  hardware = {
    graphics = {
      enable = true;
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

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  system.stateVersion = "24.05";

  services.logind = {
    lidSwitch = "ignore";
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 53 80 443 8080 8001 8081 ];
    allowedUDPPorts = [ 53 80 443 8080 8001 8081 ];
  };

  # Podman
  boot.kernelModules = [ "kvm-intel" ];

  security-keys.signingkey = "/home/dgarifullin/.ssh/germany_id_rsa";

  home.programs.git.extraConfig.user = {
    signingkey = "/home/dgarifullin/.ssh/germany_id_rsa.pub";
  };
}
