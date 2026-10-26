{ pkgs, lib, system, charon-key, learnharness }:
let
  customPkgs = import ./pkgs { inherit pkgs lib system; };
in
customPkgs // {
  charon-key = charon-key.packages.${system}.default;
  learnharness = learnharness.packages.${system}.default;
}
