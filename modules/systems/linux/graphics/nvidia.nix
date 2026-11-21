# NVIDIA GPU drivers and settings - Linux system module
{
  lib,
  pkgs,
  ...
}@args:

lib.my.mkSystemModuleV2 args {
  namespace = "linux";
  description = "NVIDIA GPU drivers and settings";
  cascade = false;

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

    branch = lib.mkOption {
      type = lib.types.str;
      default = "latest";
      description = "NVIDIA driver branch from boot.kernelPackages.nvidiaPackages (e.g. stable, production, latest, beta, vulkan_beta)";
    };
  };

  module =
    cfg:
    lib.mkMerge [
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
          # Track the newest official NVIDIA release branch (new_feature/production)
          # via NixOS's native hardware.nvidia.branch option; vulkan_beta lags behind
          # Linux 7.3+ kernel compatibility (fails on removed kernel strncpy).
          branch = cfg.branch;
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
