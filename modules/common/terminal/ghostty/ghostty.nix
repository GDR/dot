{ config, options, lib, pkgs, system, ... }: with lib;
let
  cfg = config.modules.common.terminal.ghostty;
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
