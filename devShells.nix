# Development shells for the flake
{ pkgs }:
{
  default = pkgs.mkShell {
    buildInputs = [
      pkgs.nixpkgs-fmt
      pkgs.deadnix
      pkgs.statix
      pkgs.gitleaks
      pkgs.pre-commit # Custom package from overlays/additions.nix without Swift dependency
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
