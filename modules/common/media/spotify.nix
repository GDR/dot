{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.media.spotify;
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  options.modules.common.media.spotify = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = {
    home.packages = with pkgs; [
      spotify
    ];
  };
}
