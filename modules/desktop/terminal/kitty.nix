 { config, options, lib, ... }: with lib;
let
  cfg = config.modules.desktop.terminal.kitty;
in {
  options.modules.desktop.terminal.kitty = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.programs = {
      kitty.enable = true;
    };

    # Add config file for awesome wm
    home.file.".config/kitty".source = ../../../dotfiles/kitty;
  };
}
