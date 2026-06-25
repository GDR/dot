# Upstream package patches and overrides
_: prev:
{
  # direnv's checkPhase runs `zsh ./test/direnv-test.zsh` which hangs inside
  # the Nix sandbox (no /dev/tty, restricted shell env). Skip it — the package
  # is upstream-tested and this has no functional impact.
  direnv = prev.direnv.overrideAttrs (_: {
    doCheck = false;
  });

  # vte-0.84.0 fails to build in nixpkgs-unstable: unused-variable warnings in
  # vte.cc are promoted to errors by -Werror. Disable werror until upstream fixes it.
  # Affects: termite, gnome-terminal, and any other VTE-based terminal.
  vte = prev.vte.overrideAttrs (old: {
    mesonFlags = (old.mesonFlags or [ ]) ++ [ "--warnlevel=0" ];
  });
}
