{ config, options, lib, pkgs, ... }:
with lib;
let
  mod = lib.my.modulePath [ "linux" "games" "lutris" ] config;
  cfg = mod.cfg;
in
{

  options.modules.linux.games.lutris = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
      description = "Enable Lutris game launcher";
    };

    enableGamescope = mkOption {
      default = true;
      type = types.bool;
      description = "Whether to enable Gamescope support for Lutris";
    };

    extraPackages = mkOption {
      default = [ ];
      type = types.listOf types.package;
      description = "Extra packages to install alongside Lutris (e.g., wine, winetricks)";
    };
  };

  config = mkIf cfg.enable {
    # Install Lutris with extraPackages in FHS environment
    # extraPackages must be installed via FHS override so they're available to games/Wine
    home.packages = with pkgs; [
      (lutris.override {
        extraPkgs = pkgs: cfg.extraPackages;
      })
    ];

    # Enable Gamescope as a system program if requested
    programs.gamescope = mkIf cfg.enableGamescope {
      enable = true;
      # Required for some performance features (like FSR/HDR)
      # Note: If Steam is also enabled, capSysNice will be false (required for Steam's FHS)
      # This setting only applies when Steam is not enabled
      capSysNice = mkDefault true;
    };
  };
}
