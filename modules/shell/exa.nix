{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.shell.exa;
in {
  options.modules.shell.exa = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [ exa ];
  };
}
