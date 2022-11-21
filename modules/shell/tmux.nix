{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.shell.tmux;
in {
  options.modules.shell.tmux = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [ tmux ];
  };
}
