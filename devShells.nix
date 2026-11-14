# Development shells for the flake
{ pkgs, customPkgs }:
{
  default = pkgs.mkShell {
    buildInputs = [
      pkgs.nixpkgs-fmt
      pkgs.deadnix
      pkgs.statix
      pkgs.gitleaks
      customPkgs.pre-commit # Our custom package without Swift dependency
      pkgs.just
    ];
    shellHook = ''
      pre-commit install -f --hook-type pre-commit --hook-type pre-push >/dev/null 2>&1

      # Load environment variables from .env file
      if [ -f .env ]; then
        set -a
        source .env
        set +a
      fi
    '';
  };
}
