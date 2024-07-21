{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.utils.qbittorrent;
in
{
  options.modules.common.utils.qbittorrent = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      qbittorrent
    ];
  };
}
