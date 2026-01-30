# Cursor IDE - AI-powered code editor
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  tags = [ "editors-ui" ];
  platforms = [ "linux" "darwin" ];
  description = "Cursor IDE - AI-powered code editor";
  module = {
    nixosSystems.home.packages = [ pkgs.code-cursor pkgs.cursor-cli ];
    darwinSystems.homebrew.casks = [ "cursor" ];
  };
}
