# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ pkgs ? (import ../nixpkgs.nix) { }, system, ... }:
let
  isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
  isLinux = system == "aarch64-linux" || system == "x86_64-linux";

  common = {
    apple-emoji-ttf = pkgs.callPackage ./apple-emoji-ttf { };
  };
  linux = {
    lmstudio = pkgs.callPackage ./lmstudio { };
  };
  darwin = {
    vfkit = pkgs.callPackage ./vfkit { };
  };
in
common // (if isLinux then linux else { }) // (if isDarwin then darwin else { })
