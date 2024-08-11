{ config, options, pkgs, lib, system, ... }: with lib;
let
  cfg = config.modules.common.virtualisation.kubernetes;
  mkModule = lib.my.mkModule system;
in
{
  options.modules.common.virtualisation.kubernetes = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable (mkModule {
    common = {
      home.packages = with pkgs; [
        kubectl
        kubectx
      ];
    };
    linux = { };
  });
}
