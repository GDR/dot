{ lib, ... }: with lib; rec {
  # Build dependency graph and resolve all dependencies recursively
  # (kept for potential future use with module requires)
  resolveDeps = moduleMap: modulePath: visited:
    if elem modulePath visited then visited
    else
      let
        moduleMeta = moduleMap.${modulePath} or null;
        deps = if moduleMeta != null then (moduleMeta.requires or [ ]) else [ ];
        newVisited = visited ++ [ modulePath ];
      in
      foldl (acc: dep: resolveDeps moduleMap dep acc) newVisited deps;

  # Convert module path to config path parts
  # "home.browsers.firefox" -> [ "home" "browsers" "firefox" ]
  pathToConfigParts = path: splitString "." path;
}
