{ config, options, pkgs, lib, ... }: with lib;
let
  mod = lib.my.modulePath [ "common" "editors" "vscode" ] config;
  cfg = mod.cfg;
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
      profiles.default.extensions = with pkgs.vscode-extensions; [
        ms-azuretools.vscode-docker
        bbenoist.nix
        mkhl.direnv

        ms-python.python
        bbenoist.nix
        jnoortheen.nix-ide

        catppuccin.catppuccin-vsc
        catppuccin.catppuccin-vsc-icons

        github.vscode-github-actions
      ];
      profiles.default.userSettings = {
        "editor.fontFamily" = "'FiraCode Nerd Font Mono'";
        "editor.fontLigatures" = true;
        "editor.fontWeight" = "300";
        "extensions.autoUpdate" = true;
        "extensions.autoCheckUpdates" = true;
        "workbench.colorTheme" = "Catppuccin Mocha";
        "workbench.iconTheme" = "catppuccin-mocha";
      };
    };
  };
}
