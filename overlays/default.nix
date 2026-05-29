# Overlay aggregator
{ inputs, lib, system, ... }:
{
  # Custom packages and flake inputs
  additions = import ./additions.nix { inherit inputs system; };

  # Upstream package patches and overrides
  patches = import ./patches.nix;

  # Package modifications
  antigravity = import ./antigravity { inherit lib system; };
  ollama = import ./ollama;
  code-cursor = import ./code-cursor { inherit lib system; };
  proton-ge-bin = import ./proton-ge-bin;
  openldap = import ./openldap;
}
