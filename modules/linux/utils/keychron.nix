{ config, options, lib, pkgs, ... }:
with lib;
let
  cfg = config.modules.linux.utils.keychron;
in
{
  options.modules.linux.utils.keychron = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };

    # Common Keychron device IDs - users can override these
    devices = mkOption {
      type = listOf (submodule {
        options = {
          idVendor = mkOption {
            type = str;
            description = "USB Vendor ID for the Keychron device";
          };
          idProduct = mkOption {
            type = str;
            description = "USB Product ID for the Keychron device";
          };
          name = mkOption {
            type = str;
            description = "Device name for identification";
          };
        };
      });
      default = [
        # Common Keychron devices - add more as needed
        { idVendor = "3434"; idProduct = "0e80"; name = "Keychron K8 HE"; }
        { idVendor = "3434"; idProduct = "d030"; name = "Keychron Link"; }
      ];
      description = "List of Keychron devices to configure udev rules for";
    };

    enableAppImageSupport = mkOption {
      default = true;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    services.udev.packages = [ pkgs.qmk-udev-rules ];

    services.udev.extraRules = concatStringsSep "\n" (map
      (device: ''
        # ${device.name}
        SUBSYSTEM=="hidraw", KERNEL=="hidraw*", ATTRS{idVendor}=="${device.idVendor}", ATTRS{idProduct}=="${device.idProduct}", TAG+="uaccess", MODE="0660"
      '')
      cfg.devices);
  };
}
