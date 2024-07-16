{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.darwin.fonts;
in
{
  options.modules.darwin.fonts = with types; {
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
        fira-code-nerdfont
      ];
    };
  };
}
