# Gemini CLI - Google's AI coding assistant
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "linux" "darwin" ];
  description = "Gemini CLI - Google's AI coding assistant";
  module = {
    allSystems = {
      programs.gemini-cli = {
        enable = true;
      };
    };
  };
}
