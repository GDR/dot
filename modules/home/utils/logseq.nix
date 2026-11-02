# Logseq - Privacy-first, open-source knowledge base and note-taking app
{ lib, ... }:

lib.my.mkFeature {
  description = "Logseq knowledge base and note-taking app";

  homeModule = { pkgs, ... }: {
    home.packages = [ pkgs.logseq ];
  };
}
