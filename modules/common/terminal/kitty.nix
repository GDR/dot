{ config, options, lib, ... }: with lib;
let
  cfg = config.modules.workstation.terminal.kitty;
in
{
  options.modules.workstation.terminal.kitty = with types; {
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
