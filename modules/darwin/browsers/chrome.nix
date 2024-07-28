{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.browsers.chrome;
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  options.modules.common.browsers.chrome = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      "google-chrome"
    ];
  };
}
