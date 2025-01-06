{ ... }:
let
in {
  config.programs.nixvim = {
    plugins = {
      web-devicons = {
        enable = true;
      };
    };
  };
}
