{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.media.vlc;
  isLinux = options.system.platform == "linux";
  isDarwin = options.system.platform == "darwin";
in
{
  options.modules.common.media.vlc = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = { }
    // mkIf (cfg.enable && isLinux) { }
    // mkIf (cfg.enable && isDarwin) {
    homebrew.casks = [
      "vlc"
    ];
  };
}
