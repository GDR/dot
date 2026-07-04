# Neovim editor with nix-wrapper-modules (Lua-first config)
{ lib, pkgs, inputs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "linux" "darwin" ];
  description = "Neovim editor with Lua-first configuration";

  module = {
    # Placeholder — Phase 2 will add the wrapped neovim package
    allSystems.home.packages = with pkgs; [ neovim ripgrep fzf fd ];
  };
}
