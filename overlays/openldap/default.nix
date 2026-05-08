final: prev: {
  # Work around flaky upstream OpenLDAP test failures that block dependent
  # packages (e.g. Lutris FHS rootfs) on this nixpkgs revision.
  openldap = prev.openldap.overrideAttrs (_oldAttrs: {
    doCheck = false;
  });
}
