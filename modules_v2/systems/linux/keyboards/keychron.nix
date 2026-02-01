# Keychron keyboard udev rules - Linux system module
{ lib, pkgs, ... }@args:

lib.my.mkSystemModuleV2 args {
  namespace = "linux";
  description = "Keychron keyboard udev rules";

  extraOptions = {
    devices = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          idVendor = lib.mkOption {
            type = lib.types.str;
            description = "USB Vendor ID for the Keychron device";
          };
          idProduct = lib.mkOption {
            type = lib.types.str;
            description = "USB Product ID for the Keychron device";
          };
          name = lib.mkOption {
            type = lib.types.str;
            description = "Device name for identification";
          };
        };
      });
      default = [
        { idVendor = "3434"; idProduct = "0e80"; name = "Keychron K8 HE"; }
        { idVendor = "3434"; idProduct = "d030"; name = "Keychron Link"; }
      ];
      description = "List of Keychron devices to configure udev rules for";
    };
  };

  module = cfg: {
    services.udev.packages = [ pkgs.qmk-udev-rules ];

    services.udev.extraRules = lib.concatStringsSep "\n" (map
      (device: ''
        # ${device.name}
        SUBSYSTEM=="hidraw", KERNEL=="hidraw*", ATTRS{idVendor}=="${device.idVendor}", ATTRS{idProduct}=="${device.idProduct}", TAG+="uaccess", MODE="0660"
      '')
      cfg.devices);
  };
}
