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
  # vte.cc are promoted to errors by -Werror. Use -Dwerror=false to disable it.
  # (nixpkgs issue #525761)
  vte = prev.vte.overrideAttrs (old: {
    mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Dwerror=false" ];
  });

  # termite is unmaintained (upstream archived) and broken against vte-0.84.0.
  # Replace with an empty stub so the GNOME module's dependency on it doesn't
  # block the build. (nixpkgs issue #525761)
  termite = prev.runCommandNoCC "termite-stub" { } "mkdir -p $out";
}
