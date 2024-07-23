{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.editors.neovim;
in
{
  imports = [
    ./colorschema.nix
    ./general.nix
    ./keymaps.nix
    ./plugins/airline.nix
    ./plugins/neoscroll.nix
    ./plugins/neotree.nix
    ./plugins/noice.nix
    ./plugins/telescope.nix
    ./plugins/which-key.nix
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
