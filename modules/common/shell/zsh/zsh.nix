{ config, options, pkgs, lib, ... }: with lib;
let
  mod = lib.my.modulePath [ "common" "shell" "zsh" ] config;
  cfg = mod.cfg;
in
{
  meta = lib.my.mkModuleMeta {
    requires = [];
    platforms = [ "linux" "darwin" ];
    description = "Zsh shell configuration with oh-my-zsh and zplug";
  };

  options.modules.common.shell.zsh = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    user.shell = pkgs.zsh;

    environment.systemPackages =
      with pkgs; [
        eza
      ];

    home.file.".config/zsh".source = ./dotfiles;
    programs.zsh.enable = true;
    home.programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;

      oh-my-zsh = {
        enable = true;
      };

      zplug = {
        enable = true;
        plugins = [
          { name = "zsh-users/zsh-autosuggestions"; }
          { name = "zsh-users/zsh-syntax-highlighting"; }
          { name = "zsh-users/zsh-history-substring-search"; }
          { name = "zsh-users/zsh-completions"; }
          { name = "zsh-users/zsh-history-substring-search"; }
          { name = "zsh-users/zsh-history-substring-search"; }
        ];
      };

      initContent = ''
        source ~/.config/zsh/.p10k.zsh
        source ~/.config/zsh/common.zsh
        if [[ $(uname -m) == 'arm64' ]]; then
          eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
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
