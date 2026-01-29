# Zsh shell configuration with oh-my-zsh and zplug
{ config, pkgs, lib, system, _modulePath, self, ... }: with lib;
let
  mkModule = lib.my.mkModule system;
  modulePath = _modulePath;
  moduleTags = [ "shells" ];

  pathParts = splitString "." modulePath;
  cfg = foldl (acc: part: acc.${part}) config.modules pathParts;
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
  };

  config =
    let
      shouldEnable = lib.my.shouldEnableModule { inherit config modulePath moduleTags; };
    in
    mkIf shouldEnable (mkMerge [
      # System packages and shell setting
      (mkModule {
        nixosSystems = {
          # Set user's default shell to zsh
          users.users = builtins.listToAttrs (map
            (username: {
              name = username;
              value = { shell = pkgs.zsh; };
            })
            (builtins.attrNames (lib.filterAttrs (n: v: v.enable) config.hostUsers)));

          # Enable zsh at system level
          programs.zsh.enable = true;

          environment.systemPackages = with pkgs; [ eza ];
        };
        darwinSystems = {
          # Enable zsh at system level
          programs.zsh.enable = true;

          environment.systemPackages = with pkgs; [ eza ];
        };
      })

      # Home-manager configuration
      {
        home-manager.users = builtins.listToAttrs (
          map
            (username: {
              name = username;
              value = {
                programs.zsh = {
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
                    ];
                  };

                  initContent = ''
                    source ~/.config/zsh/.p10k.zsh
                    source ~/.config/zsh/common.zsh
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
            (builtins.attrNames (lib.filterAttrs (n: v: v.enable) config.hostUsers))
        );
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
