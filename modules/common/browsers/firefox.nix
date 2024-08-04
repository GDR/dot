{ config, options, pkgs, lib, system, ... }: with lib;
let
  moduleName = "firefox";
  cfg = config.modules.common.browsers.${moduleName};
  mkModule = lib.my.mkModule system;
in
{
  options.modules.common.browsers.${moduleName} = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable (mkModule {
    darwin = {
      homebrew.casks = [
        "firefox"
      ];
    };

    linux = {
      home.programs = {
        firefox.enable = true;
      };
    };
  });
}
