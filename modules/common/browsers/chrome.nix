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

  config = { }
    // mkIf (cfg.enable && isLinux) {
    home.programs = {
      google-chrome = {
        enable = true;
        commandLineArgs = mkIf pkgs.stdenv.isLinux [
          # Enable VAAPI support for google chrome
          "--disable-features=UseSkiaRenderer"
          "--disable-features=UseChromeOSDirectVideoDecoder"
          "--enable-features=VaapiIgnoreDriverChecks"
          "--use-gl=egl"
          "--enable-features=VaapiVideoDecoder"
        ];
      };
    };
  };
}
