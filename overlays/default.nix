# Overlay aggregator
{
  inputs,
  lib,
  system,
  ...
}:
let
  # Custom packages and flake inputs
  additions = import ./additions.nix { inherit inputs system; };

  # Upstream package patches and overrides
  patches = import ./patches.nix;

  # Package modifications
  antigravity = import ./antigravity { inherit lib system; };
  ollama = import ./ollama;
  openldap = import ./openldap;
in
{
  inherit
    additions
    patches
    antigravity
    ollama
    openldap
    ;
  list = [
    additions
    patches
    antigravity
    ollama
    openldap
  ];
}
