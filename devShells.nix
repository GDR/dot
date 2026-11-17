# Development shells for the flake
{ pkgs }:
{
  default = pkgs.mkShell {
    buildInputs = [
      pkgs.nixfmt
      pkgs.nixfmt-tree
      pkgs.deadnix
      pkgs.statix
      pkgs.gitleaks
      pkgs.actionlint
      pkgs.nixos-rebuild
      pkgs.pre-commit # Custom package from overlays/additions.nix without Swift dependency
      pkgs.just
    ];
    shellHook = ''
      if [ -d .git ] && [ ! -f .git/hooks/pre-commit ]; then
        pre-commit install -f --hook-type pre-commit --hook-type pre-push >/dev/null 2>&1
      fi
    '';
  };
}
