# Essential shell utilities
{ lib, ... }:

lib.my.mkFeature {
  description = "Essential shell utilities (bat, fzf, wget, direnv)";
  homeModule = { pkgs, ... }: {
    home.packages = with pkgs; [
      bat
      fzf
      fastfetch
      wget
    ];
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      silent = true;
    };
  };
}
