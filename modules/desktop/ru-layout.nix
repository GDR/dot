 { config, options, pkgs, lib, ... }: with lib;
let 
  cfg = config.modules.desktop.ru-layout; 
in {
  options.modules.desktop.ru-layout = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    services.xserver = {
      layout = "us,ru";
      xkbVariant = "";
      xkbOptions = "grp:alt_space_toggle";
    };
  };
}
