{ config, options, pkgs, lib, system, ... }: with lib;
let
  mod = lib.my.modulePath [ "common" "media" "vlc" ] config;
  cfg = mod.cfg;
  mkModule = lib.my.mkModule system;
in
{

  options.modules.common.media.vlc = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable (mkModule {
    darwin = {
      homebrew.casks = [
        "vlc"
      ];
    };

    linux = {
      home.packages = with pkgs; [
        vlc
      ];
    };
  });
}
