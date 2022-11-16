{ config, options, pkgs, lib, ... }: with lib;
let 
  cfg = config.modules.shell.zsh;
in {
  options.modules.shell.zsh = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    user.shell = pkgs.zsh;

    environment.sessionVariables = {
      HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE = "1";
    };

    # environment.pathsToLink = "/share/zsh";

    home.programs.zsh = {
      enable = true;
      enableCompletion = true;
      enableAutosuggestions = true;

      oh-my-zsh = {
        enable = true;
      };

      zplug = {
        enable = true;
        plugins = [
          { name = "plugins/git"; tags = ["from:oh-my-zsh"]; }
          { name = "romkatv/powerlevel10k"; tags = ["as:theme" "depth:1"]; }
          { name = "chisui/zsh-nix-shell"; tags = ["depth:1"]; }
        ];
      };

      initExtra = ''
        source ~/.p10k.zsh
      '';

      shellAliases = {
        "ls" = "exa -l --group-directories-first";
        "dotfiles" = "cd ~/.config/nixos";
      };
    };
  };
}