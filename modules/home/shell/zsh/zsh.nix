# Zsh shell configuration with oh-my-zsh and zplug
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "linux" "darwin" ];
  description = "Zsh shell configuration with oh-my-zsh and zplug";

  extraOptions = {
    showHostname = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Show hostname in the prompt (Powerlevel10k)";
    };
  };

  nixosModule = { pkgs, lib, selectedUsers, ... }: {
    programs.zsh.enable = true;
    users.users = lib.genAttrs selectedUsers (_: {
      shell = pkgs.zsh;
    });
  };

  darwinModule = { pkgs, lib, selectedUsers, ... }: {
    programs.zsh.enable = true;
    users.users = lib.genAttrs selectedUsers (_: {
      shell = pkgs.zsh;
    });
  };

  homeModule = { pkgs, lib, featureCfg, ... }:
    let
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
      showHostname = featureCfg.showHostname or true;
    in
    {
      home.packages = with pkgs; [ eza ];

      programs.atuin = {
        enable = true;
        enableZshIntegration = true;
        flags = [ "--disable-up-arrow" ];
        settings = {
          auto_sync = false;
          search_mode = "fuzzy";
          filter_mode = "global";
          filter_mode_shell_up_key_binding = "directory";
          show_preview = true;
          style = "compact";
        };
      };

      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;

        oh-my-zsh.enable = true;

        envExtra = ''
          typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
        '';

        zplug = {
          enable = true;
          plugins = [
            { name = "romkatv/powerlevel10k"; tags = [ "as:theme" "depth:1" ]; }
            { name = "zsh-users/zsh-autosuggestions"; }
            { name = "zsh-users/zsh-syntax-highlighting"; }
            { name = "zsh-users/zsh-history-substring-search"; }
            { name = "zsh-users/zsh-completions"; }
          ];
        };

        initContent = ''
          # Source p10k config if it exists
          [[ -f ~/.config/zsh/.p10k.zsh ]] && source ~/.config/zsh/.p10k.zsh
          source ~/.config/zsh/common.zsh

          # Ctrl+E edits command line in nvim (last cmd if empty)
          export EDITOR=nvim
          autoload -U edit-command-line
          zle -N edit-command-line
          edit-last-or-current() {
            [[ -z "$BUFFER" ]] && BUFFER=$(fc -ln -1 | sed 's/^[[:space:]]*//')
            zle edit-command-line
          }
          zle -N edit-last-or-current
          bindkey "\C-e" edit-last-or-current
        '' + lib.optionalString (!showHostname) ''
          # Hide hostname in prompt (set by modules.home.shell.zsh.showHostname = false)
          typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE='%n'
          typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE='%n'
        '' + lib.optionalString isDarwin ''
          if [[ $(uname -m) == 'arm64' ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
          fi
        '';

        shellAliases = {
          "vim" = "nvim";
          "vi" = "nvim";
          "c" = "cursor";
          "ls" = "eza -l --group-directories-first";
          "dotfiles" = "cd ~/Workspaces/gdr/dot";
        };
      };
    };

  dotfiles = {
    path = "zsh";
    source = "modules/home/shell/zsh/dotfiles";
  };
}
