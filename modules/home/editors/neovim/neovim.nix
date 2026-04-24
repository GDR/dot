# Neovim editor with nixvim configuration
{ lib, pkgs, ... }@args:

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
  # Temporarily disabled: current nixpkgs revision fails building nixvim
  # plugin pack with "attribute 'pname' missing".
  systemModule = { };
  module = {
    allSystems.home.packages = with pkgs; [ ripgrep fzf ];
  };
}
