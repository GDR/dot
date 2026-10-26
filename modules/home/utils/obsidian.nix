# Obsidian - Knowledge base and note-taking app
{ lib, ... }:

lib.my.mkFeature {
  description = "Obsidian knowledge base and note-taking app";

  homeModule = _: {
    programs.obsidian = {
      enable = true;
      cli.enable = true;
    };
  };
}
