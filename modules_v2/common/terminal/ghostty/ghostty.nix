# Ghostty terminal emulator
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  tags = [ "terminal" ];
  description = "Ghostty terminal emulator";
  module = {
    nixosSystems.home.packages = [ pkgs.ghostty ];
    darwinSystems.homebrew.casks = [ "ghostty" ];
  };
  dotfiles = {
    path = "ghostty";
    source = "modules_v2/common/terminal/ghostty/dotfiles";
  };
}
