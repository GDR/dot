{ config, options, lib, pkgs, system, ... }: with lib;
let
  mod = lib.my.modulePath [ "common" "terminal" "ghostty" ] config;
  cfg = mod.cfg;
  mkModule = lib.my.mkModule system;
in
{

  options.modules.common.terminal.ghostty = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable (mkModule {
    linux = {
      home.packages = with pkgs; [
        ghostty
      ];

      home.file.".config/ghostty".source = ./dotfiles;
    };

    darwin = {
      homebrew = {
        casks = [
          "ghostty"
        ];
      };

      home.file.".config/ghostty".source = ./dotfiles;
    };
  });
}
