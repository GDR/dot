{ config, options, pkgs, lib, ... }: with lib;
let
  mod = lib.my.modulePath [ "fonts" ] config;
  cfg = mod.cfg;
in
{

  options.modules.fonts = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    fonts = {
      packages = with pkgs; [
        hack-font
        pixel-code
        nerd-fonts.fira-code
      ];
    };
  };
}
