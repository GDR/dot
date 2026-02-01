# Essential shell utilities
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "linux" "darwin" ];
  description = "Essential shell utilities (bat, fzf, wget, direnv)";
  module = {
    allSystems = {
      home.packages = with pkgs; [
        bat
        fzf
        neofetch
        wget
      ];
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        silent = true; # Silence all direnv output
      };
    };
  };
}
