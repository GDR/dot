{ ... }:
let
in {
  config.programs.nixvim = {
    plugins = {
      airline = {
        enable = true;
        settings = {
          theme = "catppuccin";

          powerline_fonts = 1;
        };
      };
    };
  };
}
