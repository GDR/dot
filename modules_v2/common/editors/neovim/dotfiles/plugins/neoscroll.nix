{ ... }:
let
in {
  config.programs.nixvim = {
    plugins = {
      neoscroll = {
        enable = true;
      };
    };
  };
}
