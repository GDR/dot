 { config, options, lib, pkgs, ... }: with lib;
let
  cfg = config.modules.workstation.fonts;
  hack-font = pkgs.nerdfonts.override { fonts = [ "Hack" ]; };
in {
  options.modules.workstation.fonts = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    fonts = {
      fontDir.enable = true;
      fonts = with pkgs; [
        hack-font
      ];
    };
  };
}
