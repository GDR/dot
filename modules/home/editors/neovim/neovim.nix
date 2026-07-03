# Neovim editor with nixvim configuration
{ lib, pkgs, inputs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "linux" "darwin" ];
  description = "Neovim editor with nixvim configuration";
  imports = [
    ./dotfiles/colorschema.nix
    ./dotfiles/general.nix
    ./dotfiles/keymaps.nix
    ./dotfiles/plugins/airline.nix
    ./dotfiles/plugins/neoscroll.nix
    ./dotfiles/plugins/neotree.nix
    ./dotfiles/plugins/noice.nix
    ./dotfiles/plugins/telescope.nix
    ./dotfiles/plugins/which-key.nix
    ./dotfiles/plugins/web-devicons.nix
  ];
  systemModule = {
    # Enable nixvim (system-level NixOS option, not home-manager)
    # Must be wrapped in allSystems so mkModuleV2 unwraps it correctly
    allSystems.programs.nixvim = {
      enable = true;
      # Suppress the nixpkgs.follows mismatch warning — we intentionally
      # use our pinned nixpkgs rather than nixvim's bundled one.
      nixpkgs.source = inputs.nixpkgs;
    };
  };
  module = {
    # Keep plain Neovim available while nixvim plugin pack is disabled.
    allSystems.home.packages = with pkgs; [ ripgrep fzf ];
  };
}
