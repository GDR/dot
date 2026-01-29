# Neovim editor with nixvim configuration
{ config, pkgs, lib, system, _modulePath, ... }: with lib;
let
  mkModule = lib.my.mkModule system;
  modulePath = _modulePath;
  moduleTags = [ "editors-terminal" ];

  pathParts = splitString "." modulePath;
  cfg = foldl (acc: part: acc.${part}) config.modules pathParts;
in
{
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

  meta = lib.my.mkModuleMeta {
    tags = moduleTags;
    platforms = [ "linux" "darwin" ];
    description = "Neovim editor with nixvim configuration";
  };

  options = lib.my.mkModuleOptions modulePath {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config =
    let
      shouldEnable = lib.my.shouldEnableModule { inherit config modulePath moduleTags; };
    in
    mkIf shouldEnable (mkMerge [
      # Enable nixvim
      {
        programs.nixvim.enable = true;
      }

      # Additional packages
      (mkModule {
        nixosSystems.home.packages = with pkgs; [ ripgrep fzf ];
        darwinSystems.home.packages = with pkgs; [ ripgrep fzf ];
      })
    ]);
}
