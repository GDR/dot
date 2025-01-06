{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.editors.neovim;
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

  options.modules.common.editors.neovim = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
    };

    home.packages = with pkgs; [
      ripgrep
      fzf
    ];
  };
}
