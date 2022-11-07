{ pkgs, lib, config, ... }:
let 
    cfg = config.fontProfiles;
in {
  config = lib.mkIf cfg.enable {
    fonts.fontconfig.enable = true;
    home.packages = [ cfg.monospace.package cfg.regular.package ];
  };
}