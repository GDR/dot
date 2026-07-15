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

    headless = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Compute-only / headless mode.  When true the NVIDIA kernel module and
        CUDA libraries are available but the GPU is NOT registered as a display
        driver (no xserver.videoDrivers entry, no nvidia-settings).
        Use this when another GPU (e.g. AMD iGPU) drives the display.
      '';
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

  module = cfg: lib.mkMerge [
    {
      # Graphics (always needed for CUDA / Vulkan interop)
      hardware.graphics.enable = true;

      # NVIDIA driver settings
      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = cfg.powerManagement;
        powerManagement.finegrained = false;
        open = cfg.open;
        nvidiaSettings = !cfg.headless;
        # Try Vulkan-focused beta branch for DXVK/VKD3D stability.
        package = config.boot.kernelPackages.nvidiaPackages.vulkan_beta;
        forceFullCompositionPipeline = cfg.forceCompositionPipeline;
      };

      environment.systemPackages = [ pkgs.vulkan-tools ];
    }

    # Only register as display driver when NOT headless
    (lib.mkIf (!cfg.headless) {
      services.xserver.enable = true;
      services.xserver.videoDrivers = [ "nvidia" ];
    })
  ];
}
