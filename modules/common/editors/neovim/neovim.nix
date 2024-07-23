{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.editors.neovim;
in
{
  imports = [
    ./colorschema.nix
    ./general.nix
    ./keymaps.nix
    ./plugins/which-key.nix
    ./plugins/airline.nix
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

      # globals.mapLeader = "<space>";da
    };
  };
}
