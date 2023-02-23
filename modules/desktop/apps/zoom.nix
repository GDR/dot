{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.desktop.apps.zoom;
in {
  options.modules.desktop.apps.zoom = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      zoom-us
    ];
  };
}
