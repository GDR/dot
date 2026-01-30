# Neovim editor with nixvim configuration
{ lib, pkgs, config, ... }@args:

let
  baseModule = lib.my.mkModuleV2 args {
    tags = [ "editors-terminal" ];
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
    module = {
      allSystems.home.packages = with pkgs; [ ripgrep fzf ];
    };
  };
in
baseModule // {
  config = lib.mkMerge [
    baseModule.config
    {
      # Enable nixvim (system-level NixOS option, not home-manager)
      programs.nixvim.enable = true;
    }
  ];
}
