# Cursor IDE - AI-powered code editor
{ lib, ... }:

lib.my.mkFeature {
  description = "Cursor IDE - AI-powered code editor";
  homeModule = { pkgs, ... }: {
    programs.cursor.enable = true;
    home.packages = [ pkgs.cursor-cli ];
  };
}
