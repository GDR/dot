# macFUSE - FUSE filesystem support for macOS
# Required for mounting NTFS, SSHFS, and other FUSE-based filesystems
{ lib, pkgs, ... }@args:
lib.my.mkModuleV2 args {
  platforms = [ "darwin" ]; # macOS only
  description = "macFUSE filesystem support";

  module = {
    allSystems = {
      home.packages = with pkgs; [
        obsidian
      ];
    };
  };
}
