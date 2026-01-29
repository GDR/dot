# Cross-platform system-scope modules (Linux + Darwin)
# These are enabled via systemAll.* options
# Modules are auto-discovered recursively
{ lib, ... }:
let
  moduleTree = lib.my.recursiveDirs ./.;
  moduleFiles = lib.my.flattenModules moduleTree;
in
{
  imports = moduleFiles;
}
