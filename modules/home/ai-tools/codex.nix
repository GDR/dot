# Codex - OpenAI's AI coding agent
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "linux" "darwin" ];
  description = "Codex - OpenAI's AI coding agent CLI";
  module = {
    allSystems.programs.codex = {
      enable = true;
    };
  };
}
