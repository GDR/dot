{ config, options, lib, pkgs, ... }: with lib;
let
  mod = lib.my.modulePath [ "darwin" "media" "iina" ] config;
  cfg = mod.cfg;
in
{

  options.modules.darwin.media.iina = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      iina
    ];
  };
}
