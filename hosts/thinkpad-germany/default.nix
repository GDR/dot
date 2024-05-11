{ inputs, lib, config, pkgs, home-manager, hardware, ... }: {
  
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports = [
    hardware.nixosModules.lenovo-thinkpad-t480
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
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8096 ];
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

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  environment.shells = with pkgs; [ bashInteractive zsh ];

  system.stateVersion = "23.11";
}