{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.browsers.firefox;
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  options.modules.common.browsers.firefox = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = {} 
  // mkIf (cfg.enable && isLinux) {
    home.programs = {
      firefox = {
        enable = true;
      };
    };
  }
  // mkIf (cfg.enable && isDarwin) {
    homebrew.casks = [
      "firefox"
    ];
  };
}
