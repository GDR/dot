{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.editors.neovim;
in
{
  options.modules.common.editors.neovim = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.programs.neovim = {
      enable = true;
    };
    user.packages = with pkgs; [
      ripgrep
      rnix-lsp
      fzf
    ];
  };
}
