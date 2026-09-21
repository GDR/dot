# Obsidian - Knowledge base and note-taking app
{ lib, pkgs, ... }@args:
lib.my.mkModuleV2 args {
  description = "Obsidian knowledge base and note-taking app";

  module = {
    allSystems = {
      programs.obsidian = {
        enable = true;
        cli.enable = true;
      };
    };
  };
}
