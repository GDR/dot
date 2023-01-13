{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.desktop.apps.qbittorrent;
in {
  options.modules.desktop.apps.steam = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    programs.steam.enable = false;
  };
}
