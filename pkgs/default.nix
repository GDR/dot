# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ pkgs ? (import ../nixpkgs.nix) { } }: {
  apple-emoji-ttf = pkgs.callPackage ./apple-emoji-ttf { };
  vfkit = pkgs.callPackage ./vfkit { };
}
