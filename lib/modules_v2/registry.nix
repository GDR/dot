# Build module registry from modules_v2 directory
# This is called during import time, not module evaluation time
{ lib }:
let
  modulesDir = ../../modules_v2/common;
  
  # Use library function to build registry from the modules directory
  registry = lib.my.buildModuleRegistry modulesDir "common";
in
{
  # List of module files to import
  modules = map (m: m.file) registry.allModules;
  
  # Registry metadata for tags.nix
  moduleRegistry = registry;
}
