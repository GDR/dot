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
      extensions = with pkgs.vscode-extensions; [
        ms-azuretools.vscode-docker
        bbenoist.nix
        mkhl.direnv

        ms-python.python
        bbenoist.nix
        jnoortheen.nix-ide
      ];
    };
  };
}