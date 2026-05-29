# Upstream package patches and overrides
_: prev:
{
  # direnv's checkPhase runs `zsh ./test/direnv-test.zsh` which hangs inside
  # the Nix sandbox (no /dev/tty, restricted shell env). Skip it — the package
  # is upstream-tested and this has no functional impact.
  direnv = prev.direnv.overrideAttrs (_: {
    doCheck = false;
  });
}
