# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ pkgs ? (import ../nixpkgs.nix) { }, system, ... }:
let
  isDarwin = system == "x86_64-darwin" || system == "aarch64-darwin";
  isLinux = system == "x86_64-linux";
in
{
  apple-emoji-ttf = pkgs.callPackage ./apple-emoji-ttf { };
}
// (if isDarwin then {
  vfkit = pkgs.callPackage ./vfkit { };
} else { })
  // (if isLinux then { } else { })
