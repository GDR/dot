 { config, options, lib, pkgs, ... }: with lib;
let
  cfg = config.modules.desktop.fonts;
  hack-font = pkgs.nerdfonts.override { fonts = [ "Hack" ]; };
  apple-emoji-ttf = pkgs.apple-emoji-ttf;
in {
  options.modules.desktop.fonts = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    fonts = {
      fonts = with pkgs; [
        hack-font
        apple-emoji-ttf
      ];
      fontconfig = {
        defaultFonts = {
          emoji = [ "Apple Color Emoji" ];
        };
      };
    };
  };
}
