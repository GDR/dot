{ config, options, pkgs, lib, ... }: with lib;
let
  mod = lib.my.modulePath [ "common" "shell" "utils" ] config;
  cfg = mod.cfg;
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
      neofetch
      wget
    ];
    home.programs = {
      direnv.enable = true;
      direnv.nix-direnv.enable = true;
    };
  };
}
