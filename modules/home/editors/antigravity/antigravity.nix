# Cursor IDE - AI-powered code editor
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  description = "Antigravity - AI-powered code editor";
  module = {
    allSystems.home.packages = [ pkgs.antigravity ];
  };
}
