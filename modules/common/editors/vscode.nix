{ config, options, lib, pkgs, ... }: with lib;
let
  cfg = config.modules.editors.vscode;
in
{
  options.modules.editors.vscode = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.gdr.programs.vscode = {
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
