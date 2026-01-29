# NVIDIA GPU drivers and settings - Linux system module
{ config, pkgs, lib, ... }: with lib;
let
  cfg = config.systemLinux.graphics.nvidia;
in
{
  options.systemLinux.graphics.nvidia = {
    enable = mkEnableOption "NVIDIA GPU drivers and settings";

    open = mkOption {
      type = types.bool;
      default = true;
      description = "Use open source kernel modules (recommended for newer GPUs)";
    };

    powerManagement = mkOption {
      type = types.bool;
      default = false;
      description = "Enable NVIDIA power management (for laptops)";
    };

    forceCompositionPipeline = mkOption {
      type = types.bool;
      default = true;
      description = "Force full composition pipeline to prevent tearing";
    };
  };

  config = mkIf cfg.enable {
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
