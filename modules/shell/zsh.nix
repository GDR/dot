{ config, options, pkgs, lib, ... }: with lib;
let 
  cfg = config.modules.shell.zsh; 
  hm = config.home-manager.users.gdr;
in {
  options.modules.shell.zsh = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    programs = {
      zsh = {
        enable = true;
        enableCompletion = true;
        shellAliases = {
          "ls" = "ls -l --color --group-directories-first";
          "dotfiles" = "cd ~/.config/nixos";
        };
        # plugins = [];
        ohMyZsh = {
          enable = true;
          plugins = [ 
            "git"

          ];
          theme = "agnoster";
        };
      };
    };

    user.shell = pkgs.zsh;

    home.programs.zsh = {
      plugins = [
        "git"
        {
          name = "zsh-nix-shell";
          file = "nix-shell.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "chisui";
            repo = "zsh-nix-shell";
            rev = "v0.5.0";
            sha256 = "0za4aiwwrlawnia4f29msk822rj9bgcygw6a8a6iikiwzjjz0g91";
          };
        }
      ];
    };
  };
}