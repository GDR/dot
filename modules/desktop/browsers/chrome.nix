{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.desktop.browsers.chrome;
in {
  options.modules.desktop.browsers.chrome = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.gdr.programs.google-chrome = {
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
}
