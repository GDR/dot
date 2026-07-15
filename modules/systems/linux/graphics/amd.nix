# AMD GPU drivers and settings - Linux system module
{ lib, pkgs, ... }@args:

lib.my.mkSystemModuleV2 args {
  namespace = "linux";
  description = "AMD GPU drivers and settings";

  extraOptions = {
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        libva-vdpau-driver
        libvdpau-va-gl
      ];
      description = "Additional AMD graphics packages for VA-API/VDPAU";
    };
  };

  module = cfg: {
    # Use the kernel modesetting driver (amdgpu is loaded automatically)
    services.xserver.videoDrivers = [ "modesetting" ];

    # Graphics / Vulkan / VA-API
    hardware.graphics = {
      enable = true;
      extraPackages = cfg.extraPackages;
    };

    environment.systemPackages = with pkgs; [ vulkan-tools ];
  };
}
