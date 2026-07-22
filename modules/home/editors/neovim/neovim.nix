# Neovim editor backed by github:GDR/nvim.nix Flake
{ lib, pkgs, inputs, ... }@args:

let
  wrappedNeovim = inputs.nvim-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
lib.my.mkModuleV2 args {
  platforms = [ "linux" "darwin" ];
  description = "Neovim editor with Lua-first configuration";

  module = {
    # The wrapped neovim has plugins + LSPs on its PATH.
    # ripgrep/fzf/fd also added globally for shell usage.
    allSystems.home.packages = [ wrappedNeovim ] ++ (with pkgs; [ ripgrep fzf fd ]);
    allSystems.xdg.configFile."nvim".source = "${inputs.nvim-nix}/dotfiles/nvim";
    # wl-clipboard is the Wayland clipboard provider; pbcopy/pbpaste are built-in on Darwin
    nixosSystems.home.packages = [ pkgs.wl-clipboard ];
  };
}
