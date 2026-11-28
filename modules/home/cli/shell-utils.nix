# Essential shell utilities
{ lib, ... }:

lib.my.mkFeature {
  description = "Essential shell utilities (bat, fzf, wget, direnv)";
  homeModule =
    { pkgs, ... }:
    let
      nrun = pkgs.writeShellScriptBin "nrun" ''
        if [ $# -eq 0 ]; then
          echo "Usage: nrun <pkg> [args...]" >&2
          exit 1
        fi
        pkg="$1"
        shift
        printf -v cmd '%q' "$pkg"
        if [ $# -gt 0 ]; then
          printf -v args ' %q' "$@"
          cmd+="$args"
        fi
        exec nix-shell -p "$pkg" --run "$cmd"
      '';
    in
    {
      home.packages = with pkgs; [
        bat
        fzf
        fastfetch
        wget
        nrun
      ];
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        silent = true;
      };
    };
}
