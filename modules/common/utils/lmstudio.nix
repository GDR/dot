{ config, options, pkgs, lib, system, ... }: with lib;
let
  moduleName = "lmstudio";
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
    linux = {
      environment.systemPackages = with pkgs; [
        lmstudio
      ];
    };
  });
}
