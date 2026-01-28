{ config, options, pkgs, lib, ... }: with lib;
let
  mod = lib.my.modulePath [ "common" "utils" "bitwarden" ] config;
  cfg = mod.cfg;
in
{

  options.modules.common.utils.bitwarden = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      bitwarden
    ];
  };
}
