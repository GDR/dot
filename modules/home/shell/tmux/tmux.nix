# Tmux terminal multiplexer
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  description = "Tmux terminal multiplexer";

  module = {
    allSystems = {
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
    };
  };

  dotfiles = {
    path = "tmux";
    source = "modules/home/shell/tmux/dotfiles";
  };
}
