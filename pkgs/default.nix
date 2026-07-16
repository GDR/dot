# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ pkgs ? (import ../nixpkgs.nix) { }, system, ... }:
let
  isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
  isLinux = system == "aarch64-linux" || system == "x86_64-linux";

  common = {
    apple-emoji-ttf = pkgs.callPackage ./apple-emoji-ttf { };
    caveman-skills = pkgs.callPackage ./caveman-skills { };
    # Custom pre-commit to avoid Swift dependency on Darwin
    pre-commit = pkgs.callPackage ./pre-commit { };
  };

  # mcp SDK 1.28.1 — nixpkgs has 1.27.0 but ghidra-mcp requires >=1.28.1
  python-mcp = pkgs.python3Packages.callPackage ./python-mcp { };

  linux = {
    lmstudio = pkgs.callPackage ./lmstudio { };
    inherit python-mcp;
    ghidra-mcp = pkgs.callPackage ./ghidra-mcp { inherit python-mcp; };
  };
  darwin = {
    vfkit = pkgs.callPackage ./vfkit { };
  };
in
common // (if isLinux then linux else { }) // (if isDarwin then darwin else { })

