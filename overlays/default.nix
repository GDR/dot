# Overlay aggregator
{ inputs, lib, system, ... }:
{
  # Custom packages and flake inputs
  additions = import ./additions.nix { inherit inputs system; };

  # Package modifications
  ollama = import ./ollama;
  code-cursor = import ./code-cursor { inherit lib system; };
}
