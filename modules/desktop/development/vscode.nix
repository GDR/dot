{ config, options, lib, pkgs, ... }: with lib;
let
  cfg = config.modules.desktop.development.vscode;
in {
  options.modules.desktop.development.vscode = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.gdr.programs.vscode = {
      enable = true;
      extensions = with pkgs.vscode-extensions; [
        ms-vscode.cpptools
      ];
    };
  };
}
