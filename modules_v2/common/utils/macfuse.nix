# macFUSE - FUSE filesystem support for macOS
# Required for mounting NTFS, SSHFS, and other FUSE-based filesystems
{ lib, ... }@args:
lib.my.mkModuleV2 args {
  tags = [ "utils" ];
  platforms = [ "darwin" ]; # macOS only
  description = "macFUSE filesystem support";

  module = {
    darwinSystems = {
      homebrew.casks = [ "macfuse" ];
    };
  };
}

