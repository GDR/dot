{ lib, config ? null, ... }:
let
  moduleTree = lib.my.recursiveDirs ./.;
  moduleFiles = lib.my.flattenModules moduleTree;

  # Import modules and extract metadata
  # Exclude tags.nix as it's a special module that uses the registry
  # Exclude vlc.nix as it's being migrated to modules_v2
  moduleFilesFiltered = lib.filter
    (path:
      ! lib.hasSuffix "tags.nix" path &&
      ! lib.hasSuffix "media/vlc.nix" path
    )
    moduleFiles;

  # Try to extract metadata from modules
  # Modules may need various arguments, so we try with minimal args
  # and catch errors (meta should be at top level and not depend on args)
  # We need to provide lib with my extension for mkModuleMeta to work
  tryImportMeta = path:
    let
      # Create a minimal lib with my extension for metadata extraction
      libWithMy = lib // {
        my = import ../lib { inherit lib; };
      };
      # Try importing with minimal args - meta should be accessible
      moduleResult = builtins.tryEval (import path {
        config = { };
        options = { };
        pkgs = { };
        lib = libWithMy;
        system = "x86_64-linux"; # Dummy system
      });
    in
    if moduleResult.success then
    # Try both _meta and meta (for backward compatibility)
      (moduleResult.value._meta or moduleResult.value.meta or null)
    else null;

  modulesWithMeta = map
    (path:
      let
        # Extract module path from file path
        # e.g., "./browsers/firefox.nix" -> "common.browsers.firefox"
        relativePath = lib.removePrefix "./" (lib.removeSuffix ".nix" path);
        fullPath = "common." + (lib.replaceStrings [ "/" ] [ "." ] relativePath);
        meta = tryImportMeta path;
      in
      {
        file = path;
        path = fullPath;
        meta = meta;
      }
    )
    moduleFilesFiltered;

  # Separate modules with and without metadata
  modulesWithMetaList = lib.filter (m: m.meta != null) modulesWithMeta;
in
{
  # Regular module list (for backward compatibility)
  modules = map (m: m.file) modulesWithMeta;

  # Set module registry as config option so other modules can access it
  # Only set if config is available (when evaluated as a module, not during import)
} // (if config != null then {
  config._moduleRegistry = {
    modules = modulesWithMetaList;
    allModules = modulesWithMeta;
  };
} else { })
