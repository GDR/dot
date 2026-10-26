# macFUSE - FUSE filesystem support for macOS
# Required for mounting NTFS, SSHFS, and other FUSE-based filesystems
# Note: nixpkgs only provides macfuse-stubs (build-time headers); the macOS kernel extension (.fs) requires Homebrew cask
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "darwin" ]; # macOS only
  description = "macFUSE filesystem support";

  darwinModule = {
    homebrew.casks = [ "macfuse" ];
  };
}
