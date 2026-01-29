# Keychron keyboard udev rules - Linux system module
{ config, pkgs, lib, ... }: with lib;
let
  cfg = config.systemLinux.keyboards.keychron;
in
{
  options.systemLinux.keyboards.keychron = {
    enable = mkEnableOption "Keychron keyboard udev rules";

    devices = mkOption {
      type = types.listOf (types.submodule {
        options = {
          idVendor = mkOption {
            type = types.str;
            description = "USB Vendor ID for the Keychron device";
          };
          idProduct = mkOption {
            type = types.str;
            description = "USB Product ID for the Keychron device";
          };
          name = mkOption {
            type = types.str;
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
