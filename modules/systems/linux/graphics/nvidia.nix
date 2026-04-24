# NVIDIA GPU drivers and settings - Linux system module
{ lib, config, pkgs, ... }@args:

lib.my.mkSystemModuleV2 args {
  namespace = "linux";
  description = "NVIDIA GPU drivers and settings";

  extraOptions = {
    open = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use open source kernel modules";
    };

    powerManagement = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable NVIDIA power management (for laptops)";
    };

    forceCompositionPipeline = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Force full composition pipeline (mainly useful for X11)";
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
      # Try Vulkan-focused beta branch for DXVK/VKD3D stability.
      package = config.boot.kernelPackages.nvidiaPackages.vulkan_beta;
      forceFullCompositionPipeline = cfg.forceCompositionPipeline;
    };

    environment.systemPackages = [ pkgs.vulkan-tools ];
  };
}
