{ config, options, pkgs, lib, ... }: with lib;
let
  mod = lib.my.modulePath [ "common" "shell" "tmux" ] config;
  cfg = mod.cfg;
in
{

  options.modules.common.shell.tmux = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.programs = {
      tmux = {
        enable = true;
      };
    };
  };
}
