{ config, options, pkgs, lib, system, ... }: with lib;
let
  cfg = config.modules.common.browsers.chrome;
  mkModule = lib.my.mkModule system;
in
{
  options.modules.common.browsers.chrome = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable (mkModule {
    darwin = {
      homebrew.casks = [
        "google-chrome"
      ];
    };

    linux = {
      home.programs = {
        google-chrome = {
          enable = true;
          commandLineArgs = [
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
  });
}
