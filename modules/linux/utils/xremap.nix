{ config, options, lib, pkgs, ... }:
with lib;
let
  cfg = config.modules.linux.utils.xremap;
in
{
  options.modules.linux.utils.xremap = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
      description = "Enable xremap key remapping service";
    };

    configFile = mkOption {
      type = path;
      default = ./xremap-config.yml;
      description = "Path to xremap configuration file";
    };

    userName = mkOption {
      type = str;
      default = config.user.name;
      description = "Username for xremap service";
    };
  };

  config = mkIf cfg.enable {
    # Install xremap package
    environment.systemPackages = with pkgs; [
      xremap
    ];

    # Add user to input group for device access
    users.users.${cfg.userName}.extraGroups = [ "input" "uinput" ];

    # Enable uinput kernel module
    boot.kernelModules = [ "uinput" ];

    # Create udev rules for input devices
    services.udev.extraRules = ''
      KERNEL=="uinput", GROUP="uinput", MODE="0666"
      KERNEL=="event*", GROUP="input", MODE="0660"
    '';

    # Create uinput group
    users.groups.uinput = { };

    # Create systemd user service for xremap
    systemd.user.services.xremap = {
      description = "xremap key remapping service";
      wantedBy = [ "default.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.xremap}/bin/xremap ${cfg.configFile}";
        Restart = "always";
        RestartSec = "3";
      };
      environment = {
        # Ensure xremap can access Wayland/X11
        DISPLAY = ":0";
        WAYLAND_DISPLAY = "wayland-0";
      };
    };

    # Enable the service by default
    systemd.user.services.xremap.enable = true;
  };
}
