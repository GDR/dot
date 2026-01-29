# Linux system-scope modules - services, drivers, WM, networking
# These are enabled via systemLinux.* options, not via tags
# Modules are auto-discovered recursively
{ lib, ... }:
let
  moduleTree = lib.my.recursiveDirs ./.;
  moduleFiles = lib.my.flattenModules moduleTree;
in
{
  imports = moduleFiles;
}
