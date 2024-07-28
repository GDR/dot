{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.media.vlc;

in
{
  options.modules.common.media.vlc = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      "vlc"
    ];
  };
}
