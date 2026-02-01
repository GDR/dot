# NVIDIA GPU drivers and settings - Linux system module
{ lib, config, ... }@args:

lib.my.mkSystemModuleV2 args {
  namespace = "linux";
  description = "NVIDIA GPU drivers and settings";

  extraOptions = {
    open = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use open source kernel modules (recommended for newer GPUs)";
    };

    powerManagement = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable NVIDIA power management (for laptops)";
    };

    forceCompositionPipeline = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Force full composition pipeline to prevent tearing";
    };
  };

  module = cfg: {
    # X11/Wayland with NVIDIA
    services.xserver.enable = true;
    services.xserver.videoDrivers = [ "nvidia" ];

    # Graphics
    hardware.graphics.enable = true;

    # NVIDIA driver settings
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = cfg.powerManagement;
      powerManagement.finegrained = false;
      open = cfg.open;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      forceFullCompositionPipeline = cfg.forceCompositionPipeline;
    };
  };
}
