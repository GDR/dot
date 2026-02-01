# Custom packages exported by the flake
{ pkgs, lib, system, charon-key }:
let
  customPkgs = import ./pkgs { inherit pkgs lib system; };
in
customPkgs // {
  charon-key = charon-key.packages.${system}.default;
}
