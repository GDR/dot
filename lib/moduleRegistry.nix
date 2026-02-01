{ lib, ... }: with lib; rec {
  # Build dependency graph and resolve all dependencies recursively
  resolveDeps = moduleMap: modulePath: visited:
    if elem modulePath visited then visited
    else
      let
        moduleMeta = moduleMap.${modulePath} or null;
        deps = if moduleMeta != null then (moduleMeta.requires or [ ]) else [ ];
        newVisited = visited ++ [ modulePath ];
      in
      foldl (acc: dep: resolveDeps moduleMap dep acc) newVisited deps;

  # Get all modules matching tags
  modulesByTags = modulesMetadata: tags:
    filter
      (m:
        any (tag: elem tag m.meta.tags) tags
      )
      modulesMetadata;

  # Get all modules to enable based on tags and explicit enables
  resolveEnabledModules = modulesMetadata: enabledTags: explicitEnabled:
    let
      # Build module map: path -> metadata
      moduleMap = listToAttrs (
        map (m: nameValuePair m.path m.meta) modulesMetadata
      );

      # Modules enabled by tags
      tagEnabled = modulesByTags modulesMetadata enabledTags;

      # All enabled paths (from tags + explicit)
      enabledPaths =
        (map (m: m.path) tagEnabled)
        ++ explicitEnabled;

      # Resolve all dependencies recursively
      allPaths = foldl
        (acc: path:
          resolveDeps moduleMap path acc
        ) [ ]
        enabledPaths;
    in
    unique allPaths;

  # Convert module path to config path parts
  # "home.browsers.firefox" -> [ "home" "browsers" "firefox" ]
  pathToConfigParts = path: splitString "." path;
}
