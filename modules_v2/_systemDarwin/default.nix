# Darwin system-scope modules - services, system settings
# These are enabled via systemDarwin.* options, not via tags
# Modules are auto-discovered recursively
{ lib, ... }:
let
  moduleTree = lib.my.recursiveDirs ./.;
  moduleFiles = lib.my.flattenModules moduleTree;
in
{
  imports = moduleFiles;
}
