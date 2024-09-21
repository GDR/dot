{ config, options, pkgs, lib, system, ... }: with lib;
let
  moduleName = "ollama";
  cfg = config.modules.common.utils.${moduleName};
  mkModule = lib.my.mkModule system;
in
{
  options.modules.common.utils.${moduleName} = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable (mkModule {
    darwin = {
      homebrew.casks = [
        "ollama"
      ];
    };
  });
}
