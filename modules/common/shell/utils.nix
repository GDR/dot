{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.shell.utils;
in
{
  options.modules.common.shell.utils = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      bat
      fzf
    ];
    home.programs = {
      direnv.enable = true;
      direnv.nix-direnv.enable = true;
    };
  };
}
