{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.development.direnv;
in {
  options.modules.development.direnv = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.programs.direnv.enable = true;
    home.programs.direnv.nix-direnv.enable = true;
  };
}
