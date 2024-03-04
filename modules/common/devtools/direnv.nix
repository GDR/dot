{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.devtools.direnv;
in
{
  options.modules.common.devtools.direnv = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.gdr.programs.direnv.enable = true;
    home-manager.users.gdr.programs.direnv.nix-direnv.enable = true;
  };
}
