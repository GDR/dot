{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.media.vlc;

in
{
  config = mkIf cfg.enable {
    homebrew.casks = [
      "vlc"
    ];
  };
}
