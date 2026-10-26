# Build module registry and catalog features from modules directory and private-extension
# This is called during import time, not module evaluation time
{ lib, inputs ? { } }:
let
  modulesDir = ../home;

  extFeatures = inputs.private-extension.dotExtension.features or [ ];

  # Use library function to build registry and feature catalog
  registry = lib.my.buildModuleRegistry modulesDir "home" extFeatures;
in
{
  # List of module files to import
  modules = map (m: m.file) registry.allModules;

  # Registry metadata
  moduleRegistry = registry;

  # Feature catalog
  features = registry.features or [ ];
  featureCatalog = registry.featureCatalog or [ ];
}
