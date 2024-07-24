{ ... }:
let
in {
  config.programs.nixvim = {
    plugins = {
      noice = {
        enable = true;
      };
    };
  };
}
