# Intel GPU drivers and settings - Linux system module
{ lib, pkgs, config, ... }@args:

lib.my.mkSystemModuleV2 args {
  namespace = "linux";
  description = "Intel GPU drivers and settings";

  extraOptions = {
    enableHybridCodec = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable hybrid codec support for vaapiIntel";
    };

    tearFree = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable TearFree option in X11 device section";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        intel-media-driver
        libvdpau-va-gl
        libva-vdpau-driver
      ];
      description = "Additional Intel graphics packages";
    };
  };

  module = cfg: {
    # X11 video drivers
    services.xserver.videoDrivers = [ "modesetting" ];

    # TearFree option for X11
    services.xserver.deviceSection = lib.mkIf cfg.tearFree ''
      Option "TearFree" "true"
    '';

    # Package override for vaapiIntel with hybrid codec
    nixpkgs.config.packageOverrides = lib.mkIf cfg.enableHybridCodec (
      pkgs: {
        vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
      }
    );

    # Hardware graphics with extra packages
    hardware.graphics = {
      enable = true;
      extraPackages = cfg.extraPackages;
    };
  };
}

