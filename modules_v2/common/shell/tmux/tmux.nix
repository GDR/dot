# Tmux terminal multiplexer
{ config, pkgs, lib, system, _modulePath, self, ... }: with lib;
let
  modulePath = _modulePath;
  moduleTags = [ "shells" ];
  enabledUsers = filterAttrs (_: u: u.enable) config.hostUsers;
in
{
  meta = lib.my.mkModuleMeta {
    tags = moduleTags;
    platforms = [ "linux" "darwin" ];
    description = "Tmux terminal multiplexer";
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
      # Tmux program configuration
      {
        home-manager.users = mapAttrs
          (name: _: {
            programs.tmux = {
              enable = true;
              shell = "${pkgs.zsh}/bin/zsh";
              terminal = "tmux-256color";
              historyLimit = 10000;
              keyMode = "vi";
              mouse = true;
              baseIndex = 1;
              escapeTime = 0;

              plugins = with pkgs.tmuxPlugins; [
                sensible
                yank
                resurrect
                continuum
              ];

              extraConfig = ''
                # Source custom config from dotfiles
                source-file ~/.config/tmux/tmux.conf
              '';
            };
          })
          enabledUsers;
      }

      # Dotfiles symlink (live-editable)
      {
        home-manager.users = lib.my.mkDotfilesSymlink {
          inherit config self;
          path = "tmux";
          source = "modules_v2/common/shell/tmux/dotfiles";
        };
      }
    ]);
}
