{ pkgs, lib, system, charon-key, inputs ? { } }:
let
  customPkgs = import ./pkgs { inherit pkgs lib system inputs; };
in
customPkgs // {
  charon-key = charon-key.packages.${system}.default;
}
