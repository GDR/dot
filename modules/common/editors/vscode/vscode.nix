{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.editors.vscode;
in
{
  options.modules.common.editors.vscode = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.programs.vscode = {
      enable = true;
    };
  };
}