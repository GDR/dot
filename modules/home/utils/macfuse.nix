# macFUSE - FUSE filesystem support for macOS
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "darwin" ];
  description = "macFUSE filesystem support";

  darwinModule = {
    homebrew.casks = [ "macfuse" ];
  };
}
