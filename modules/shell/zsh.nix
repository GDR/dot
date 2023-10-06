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

    home.file.".config/zsh".source = ../../dotfiles/zsh;
    programs.zsh.enable = true;
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
        source ~/.config/zsh/.p10k.zsh
        source ~/.config/zsh/common.zsh
      '';

      shellAliases = {
        "vim" = "nvim";
        "vi" = "nvim";
        "ls" = "eza -l --group-directories-first";
        "dotfiles" = "cd ~/Workspaces/gdr/github/dot";
      };
    };
  };
}
