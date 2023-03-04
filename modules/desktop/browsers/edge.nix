{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.desktop.browsers.edge;
in {
  options.modules.desktop.browsers.edge = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      microsoft-edge
    ];
  };
}
