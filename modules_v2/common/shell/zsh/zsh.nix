# Zsh shell configuration with oh-my-zsh and zplug
{ config, pkgs, lib, system, _modulePath, self, ... }: with lib;
let
  modulePath = _modulePath;
  moduleTags = [ "shells" ];
  isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
in
{
  meta = lib.my.mkModuleMeta {
    tags = moduleTags;
    platforms = [ "linux" "darwin" ];
    description = "Zsh shell configuration with oh-my-zsh and zplug";
  };

  options = lib.my.mkModuleOptions modulePath {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
    showHostname = mkOption {
      default = true;
      type = types.bool;
      description = "Show hostname in the prompt (Powerlevel10k)";
    };
  };

  config =
    let
      shouldEnable = lib.my.shouldEnableModule { inherit config modulePath moduleTags; };
      enabledUsers = lib.filterAttrs (n: v: v.enable) config.hostUsers;
      enabledUsernames = builtins.attrNames enabledUsers;
      pathParts = splitString "." modulePath;
      cfg = foldl (acc: part: acc.${part}) config.modules pathParts;
    in
    mkIf shouldEnable (mkMerge [
      # System-level config (NixOS programs.zsh, users.users)
      {
        # Enable zsh at system level (required for users to use zsh as shell)
        programs.zsh.enable = true;

        environment.systemPackages = with pkgs; [ eza fzf ];

        # Set user's default shell to zsh
        users.users = builtins.listToAttrs (map
          (username: {
            name = username;
            value = { shell = pkgs.zsh; };
          })
          enabledUsernames);
      }

      # Home-manager configuration for each user
      {
        home-manager.users = builtins.listToAttrs (map
          (username: {
            name = username;
            value = {
              programs.zsh = {
                enable = true;
                enableCompletion = true;
                autosuggestion.enable = true;

                oh-my-zsh.enable = true;

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

                  # FZF history search (Ctrl+R)
                  fzf-history-widget() {
                    local selected
                    selected=$(fc -rl 1 | awk '{$1=""; print substr($0,2)}' | awk '!seen[$0]++' | fzf --height 40% --reverse +s)
                    if [[ -n "$selected" ]]; then
                      BUFFER="$selected"
                      CURSOR=''${#BUFFER}
                    fi
                    zle reset-prompt
                  }
                  zle -N fzf-history-widget
                  bindkey '\C-r' fzf-history-widget

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
                '' + optionalString (!cfg.showHostname) ''
                  # Hide hostname in prompt (set by modules.common.shell.zsh.showHostname = false)
                  typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE='%n'
                  typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE='%n'
                '' + optionalString isDarwin ''
                  if [[ $(uname -m) == 'arm64' ]]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                  fi
                '';

                shellAliases = {
                  "vim" = "nvim";
                  "vi" = "nvim";
                  "ls" = "eza -l --group-directories-first";
                  "dotfiles" = "cd ~/Workspaces/gdr/dot";
                };
              };
            };
          })
          enabledUsernames);
      }

      # Dotfiles symlink (linked to repo for live editing without rebuild)
      {
        home-manager.users = lib.my.mkDotfilesSymlink {
          inherit config self;
          path = "zsh";
          source = "modules_v2/common/shell/zsh/dotfiles";
        };
      }
    ]);
}
