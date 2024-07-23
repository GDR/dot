{ ... }:
let
in {
  config.programs.nixvim = {
    plugins = {
      neo-tree = {
        enable = true;
      };
    };
  };
}
