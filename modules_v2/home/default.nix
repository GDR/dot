# Simple module directory - just returns list of module files
# Registry building and tags logic moved to lib/modules_v2/
{ lib, ... }:
let
  moduleTree = lib.my.recursiveDirs ./.;
  moduleFiles = lib.my.flattenModules moduleTree;
in
{
  modules = moduleFiles;
}
