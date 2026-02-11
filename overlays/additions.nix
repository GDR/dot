# Custom packages and flake inputs
{ inputs, system, ... }:

final: _prev:
(import ../pkgs { inherit system; pkgs = final; }) // {
  charon-key = inputs.charon-key.packages.${system}.default;
}
