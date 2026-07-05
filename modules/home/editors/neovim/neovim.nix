# Neovim editor with nix-wrapper-modules (Lua-first config)
# Plugins and LSPs are managed by Nix; configuration lives as standard Lua files
# that can be edited and reloaded instantly without nixos-rebuild.
{ lib, pkgs, inputs, system, overlays ? [], ... }@args:

let
  # Import plugin/LSP declarations
  pluginConfig = import ./dotfiles/plugins.nix { inherit pkgs lib; };

  # Build a fresh pkgs for the wrapper module to avoid NixOS module system
  # pkgs type-check issues (nix-wrapper-modules expects raw nixpkgs)
  wrapperPkgs = import inputs.nixpkgs {
    inherit system;
    config = { allowUnfree = true; };
  };

  # Build a wrapped neovim with all plugins and runtime tools baked in
  wrappedNeovim = inputs.nix-wrapper-modules.wrappers.neovim.wrap {
    pkgs = wrapperPkgs;
    inherit (pluginConfig) specs runtimePkgs;
  };
in
lib.my.mkModuleV2 args {
  platforms = [ "linux" "darwin" ];
  description = "Neovim editor with Lua-first configuration";

  module = {
    # The wrapped neovim has plugins + LSPs on its PATH.
    # ripgrep/fzf/fd also added globally for shell usage.
    allSystems.home.packages = [ wrappedNeovim ] ++ (with pkgs; [ ripgrep fzf fd ]);
  };

  # Symlink dotfiles/nvim → ~/.config/nvim for live editing
  # Edit Lua configs → restart nvim → changes apply (no rebuild needed)
  dotfiles = {
    path = "nvim";
    source = "modules/home/editors/neovim/dotfiles/nvim";
  };
}
