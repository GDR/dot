# Cursor IDE - AI-powered code editor
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "linux" "darwin" ];
  description = "Cursor IDE - AI-powered code editor";
  module = {
    allSystems = {
      programs.cursor.enable = true;
      home.packages = [ pkgs.cursor-cli ];
    };
  };
}
