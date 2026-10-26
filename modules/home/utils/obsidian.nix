# Obsidian - Knowledge base and note-taking app
{ lib, ... }:

lib.my.mkFeature {
  description = "Obsidian knowledge base and note-taking app";

  homeModule = { ... }: {
    programs.obsidian = {
      enable = true;
      cli.enable = true;
    };
  };
}
