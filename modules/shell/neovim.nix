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
    programs = {
      neovim.enable = true;
      neovim.defaultEditor = true;
    };
  };
}
