# Build module registry from modules directory
# This is called during import time, not module evaluation time
{ lib }:
let
  modulesDir = ../home;

  # Use library function to build registry from the modules directory
  registry = lib.my.buildModuleRegistry modulesDir "home";
in
{
  # List of module files to import
  modules = map (m: m.file) registry.allModules;

  # Registry metadata for tags.nix
  moduleRegistry = registry;
}
