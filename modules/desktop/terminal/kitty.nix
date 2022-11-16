 { config, options, pkgs, lib, ... }: with lib;
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
  };
}
