{ config, options, pkgs, lib, system, ... }: with lib;
let
  moduleName = "vlc";
  cfg = config.modules.common.media.${moduleName};
  mkModule = lib.my.mkModule system;
in
{
  options.modules.common.media.${moduleName} = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable (mkModule {
    darwin = {
      homebrew.casks = [
        "vlc"
      ];
    };

    linux = {
      home.packages = with pkgs; [
        vlc
      ];
    };
  });
}
