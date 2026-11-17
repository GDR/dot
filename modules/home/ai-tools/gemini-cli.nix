# Gemini CLI - Google's AI coding assistant
{ lib, ... }:

lib.my.mkFeature {
  description = "Gemini CLI - Google's AI coding assistant";
  homeModule = { pkgs, ... }: {
    home.packages = [ pkgs.gemini-cli ];
  };
}
