# Tmux terminal multiplexer
{ lib, config, pkgs, ... }@args:

let
  t = (lib.my.getTheme config).roles;
in
lib.my.mkModuleV2 args {
  description = "Tmux terminal multiplexer";

  module = {
    allSystems = {
      programs.tmux = {
        enable = false;
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
          # ── Prefix ────────────────────────────────────────────────────────
          unbind C-b
          set -g prefix C-a
          bind C-a send-prefix

          # Reload config with prefix + r
          bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

          # ── Pane splitting ────────────────────────────────────────────────
          bind | split-window -h -c "#{pane_current_path}"
          bind - split-window -v -c "#{pane_current_path}"

          # ── Pane navigation (vim keys) ────────────────────────────────────
          bind h select-pane -L
          bind j select-pane -D
          bind k select-pane -U
          bind l select-pane -R

          # ── Pane resize (vim keys) ────────────────────────────────────────
          bind -r H resize-pane -L 5
          bind -r J resize-pane -D 5
          bind -r K resize-pane -U 5
          bind -r L resize-pane -R 5

          # ── Window ────────────────────────────────────────────────────────
          bind c new-window -c "#{pane_current_path}"

          # ── Status bar (theme: ${(lib.my.getTheme config).displayName}) ──
          set -g status-style 'bg=${t.background} fg=${t.foreground}'
          set -g status-left '#[fg=${t.background},bg=${t.accent},bold] #S '
          set -g status-right '#[fg=${t.foreground}] %H:%M '
          set -g window-status-current-format '#[fg=${t.background},bg=${t.success},bold] #I:#W '
          set -g window-status-format '#[fg=${t.foregroundDim}] #I:#W '

          # ── Pane borders ──────────────────────────────────────────────────
          set -g pane-border-style 'fg=${t.border}'
          set -g pane-active-border-style 'fg=${t.borderFocused}'
        '';
      };
    };
  };
  # Note: no dotfiles key — programs.tmux manages ~/.config/tmux/tmux.conf directly.
  # Adding a dir-level dotfiles symlink here would conflict with programs.tmux output.
}
