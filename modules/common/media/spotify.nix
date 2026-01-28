{ config, options, pkgs, lib, ... }: with lib;
let
  mod = lib.my.modulePath [ "common" "media" "spotify" ] config;
  cfg = mod.cfg;
in
{

  options.modules.common.media.spotify = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = {
    home.packages = with pkgs; [
      spotify
    ];
  };
}
