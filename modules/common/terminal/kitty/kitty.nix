{ config, options, lib, ... }: with lib;
let
  mod = lib.my.modulePath [ "common" "terminal" "kitty" ] config;
  cfg = mod.cfg;
in
{

  options.modules.common.terminal.kitty = with types; {
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
    home.file.".config/kitty".source = ./dotfiles;
  };
}
