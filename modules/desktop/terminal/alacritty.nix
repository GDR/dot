 { config, options, pkgs, lib, ... }: with lib;
let 
  cfg = config.modules.desktop.terminal.alacritty; 
in {
  options.modules.desktop.terminal.alacritty = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.programs = {
      alacritty.enable = true;
    };
  };
}
