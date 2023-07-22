{ config, options, pkgs, lib, ... }: with lib;
let 
  cfg = config.modules.shell.neovim; 
in {
  options.modules.shell.neovim = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {

    # home.file.".config/nvim".source = ../../dotfiles/nvim;

    home.programs.neovim = {
      enable = true;
    };
    user.packages = with pkgs; [
      ripgrep
      rnix-lsp
    ];
  };
}
