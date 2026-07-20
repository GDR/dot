# Neovim editor with nix-wrapper-modules (Lua-first config)
# Plugins and LSPs are managed by Nix; configuration lives as standard Lua files
# that can be edited and reloaded instantly without nixos-rebuild.
{ lib, pkgs, inputs, ... }@args:

let
  wrappedNeovim = import ./dotfiles/package.nix {
    inherit inputs pkgs lib;
  };
in
lib.my.mkModuleV2 args {
  platforms = [ "linux" "darwin" ];
  description = "Neovim editor with Lua-first configuration";

  module = {
    # The wrapped neovim has plugins + LSPs on its PATH.
    # ripgrep/fzf/fd also added globally for shell usage.
    allSystems.home.packages = [ wrappedNeovim ] ++ (with pkgs; [ ripgrep fzf fd ]);
    # wl-clipboard is the Wayland clipboard provider; pbcopy/pbpaste are built-in on Darwin
    nixosSystems.home.packages = [ pkgs.wl-clipboard ];
  };

  # Symlink dotfiles/nvim → ~/.config/nvim for live editing
  # Edit Lua configs → restart nvim → changes apply (no rebuild needed)
  dotfiles = {
    path = "nvim";
    source = "modules/home/editors/neovim/dotfiles/nvim";
  };
}
