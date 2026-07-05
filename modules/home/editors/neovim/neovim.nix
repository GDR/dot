# Neovim editor with nix-wrapper-modules (Lua-first config)
# Plugins and LSPs are managed by Nix; configuration lives as standard Lua files
# that can be edited and reloaded instantly without nixos-rebuild.
{ lib, pkgs, inputs, ... }@args:

let
  # Import plugin/LSP declarations
  pluginConfig = import ./dotfiles/plugins.nix { inherit pkgs lib; };

  # Build a wrapped neovim with all plugins and runtime tools baked in
  # NOTE: NixOS pkgs can have _type = "if" (from mkIf in nixpkgs.config),
  # which causes nix-wrapper-modules to misinterpret pkgs as a conditional.
  # Override _type back to "pkgs" to fix the type check.
  wrappedNeovim = inputs.nix-wrapper-modules.wrappers.neovim.wrap {
    pkgs = pkgs // { _type = "pkgs"; };
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
