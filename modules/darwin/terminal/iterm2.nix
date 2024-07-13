{ config, options, lib, pkgs, ... }: with lib;
let
  cfg = config.modules.darwin.terminal.iterm2;
in
{
  options.modules.darwin.terminal.iterm2 = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
        iterm2
    ];
  };
}