 { config, options, lib, pkgs, ... }: with lib;
let
  cfg = config.modules.desktop.fonts;
in {
  options.modules.desktop.fonts = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    fonts.fonts = with pkgs; [
      (nerdfonts.override { fonts = [ "Hack" ]; })
    ];
  };
}
