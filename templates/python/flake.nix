{
  description = "Python environment with poetry2nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryEnv;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            (mkPoetryEnv {
              projectDir = ./.;
              python = pkgs.python312;
            })
            pkgs.poetry
          ];
          shellHook = ''
            echo "Python 3.12 environment loaded"
          '';
        };
      });
}
