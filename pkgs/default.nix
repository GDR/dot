# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ pkgs ? (import ../nixpkgs.nix) { }, system, ... }:
let
  mkModule = (import ../lib { lib = pkgs.lib; }).mkModule;
in
(mkModule system) {
  common = {
    apple-emoji-ttf = pkgs.callPackage ./apple-emoji-ttf { };
  };
  darwin = {
    vfkit = pkgs.callPackage ./vfkit { };
  };
}
