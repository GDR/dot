{ lib, ... }: with lib;
rec {
  # Build dependency graph and resolve all dependencies recursively.
  # Stops traversal at any explicitly blocked module (blockedSet) or platform-incompatible target.
  resolveDeps =
    {
      moduleMap,
      blockedSet ? { },
      hostPlatform ? null,
    }:
    modulePath: visited:
    if elem modulePath visited || (blockedSet ? ${modulePath}) then
      visited
    else
      let
        moduleMeta = moduleMap.${modulePath} or null;
        platformOk =
          hostPlatform == null
          || moduleMeta == null
          || !(moduleMeta ? platforms)
          || elem hostPlatform moduleMeta.platforms;
      in
      if !platformOk then
        visited
      else
        let
          deps = if moduleMeta != null then (moduleMeta.requires or [ ]) else [ ];
          newVisited = visited ++ [ modulePath ];
        in
        foldl (
          acc: dep: resolveDeps { inherit moduleMap blockedSet hostPlatform; } dep acc
        ) newVisited deps;

  # Convert module path to config path parts
  # "home.browsers.firefox" -> [ "home" "browsers" "firefox" ]
  pathToConfigParts = path: splitString "." path;
}
