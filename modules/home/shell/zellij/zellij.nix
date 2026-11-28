# Zellij terminal multiplexer
{ lib, ... }:

lib.my.mkFeature {
  description = "Zellij terminal multiplexer";

  homeModule =
    {
      pkgs,
      osConfig,
      lib,
      ...
    }:
    let
      theme = lib.my.getTheme osConfig;
      t = theme.roles;
      term = theme.terminal;
    in
    {
      programs.zellij = {
        enable = true;

        settings = {
          default_shell = "${pkgs.zsh}/bin/zsh";
          theme = theme.name;
          mouse_mode = true;
          pane_frames = true;
          scroll_buffer_size = 10000;
          copy_on_select = false;

          keybinds.shared._children = [
            {
              bind = {
                _args = [ "Ctrl Shift c" ];
                Copy = { };
              };
            }
          ];

          themes.${theme.name} = {
            fg = t.foreground;
            bg = t.background;
            black = term.black;
            red = term.red;
            green = term.green;
            yellow = term.yellow;
            blue = term.blue;
            magenta = term.magenta;
            cyan = term.cyan;
            white = term.white;
            orange = t.warning;
          };
        };
      };
    };
}
