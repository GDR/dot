{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      let
        mkPdf = { name }: pkgs.stdenv.mkDerivation {
          name = name;
          src = ./.;
          buildInputs = [ pkgs.texlive.combined.scheme-full ];
          buildPhase = ''
            pdflatex ${name}.tex
          '';
          installPhase = ''
            mkdir -p $out
            cp ${name}.pdf $out/
          '';
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            texlive.combined.scheme-full
          ];
        };

        packages = {
          example = mkPdf { name = "example"; };
        };
      });
}
