{ lib, inputs, ... }:
with lib;
with types;
rec {
  # Import module registry functions
  moduleRegistry = import ./moduleRegistry.nix { inherit lib; };

  # Native feature compiler and mkFeature descriptor
  features = import ./features.nix { inherit lib inputs; };
  inherit (features)
    computeModulePath
    mkFeature
    buildFeatureOptionTree
    computeEnabledFeatureSetForUser
    isFeatureEnabledForUser
    resolveUserFeatures
    compileUserDotfiles
    compileUserHomeModules
    compileSystemFeatureModules
    ;

  # ── Theme system ─────────────────────────────────────────────────────────
  # Theme registry: lib.my.themes.getTheme "rose-pine-moon"
  themes = import ./themes { inherit lib; };

  # Active theme: set via config.theme.name in host config.
  # Usage in any module: lib.my.getTheme config
  # Returns the full theme attrset (colors, roles, terminal, fonts).
  getTheme =
    config:
    let
      name = config.theme.name or "rose-pine-moon";
    in
    themes.getTheme name;

  # Factory function to create flake helpers
  # Call with: lib.my.mkFlakeHelpers { inherit self overlays; }
  # Returns: { mkDarwinConfiguration, mkNixosConfiguration, ... }
  mkFlakeHelpers =
    { self, overlays }:
    import ./flakeHelpers.nix {
      inherit
        inputs
        lib
        self
        overlays
        ;
    };

  # Re-export module registry functions for convenience
  pathToConfigParts = moduleRegistry.pathToConfigParts;

  # Minimal specialArgs for import-time feature descriptor extraction.
  # Features are pure descriptors and must not depend on pkgs, config, or system.
  dummySpecialArgs = {
    inherit inputs;
    _modulePath = "";
  };

  # Build module registry from a directory
  # This scans modules and extracts metadata, returning a registry structure
  buildModuleRegistry =
    modulesDir: _prefix:
    let
      makeRegistry =
        extFeaturesArg:
        let
          moduleTree = recursiveDirs modulesDir;
          moduleFiles = flattenModules moduleTree;

          # Filter out tags.nix and default.nix
          moduleFilesFiltered = filter (
            path: !hasSuffix "tags.nix" path && !hasSuffix "default.nix" path
          ) moduleFiles;

          libWithMy = lib // {
            inherit (lib) my;
          };

          importFeatureFile =
            path:
            let
              fullPath = computeModulePath path;
              imported = import path;
            in
            if isFunction imported then
              imported (
                dummySpecialArgs
                // {
                  lib = libWithMy;
                  _modulePath = fullPath;
                }
              )
            else
              imported;

          modulesWithMeta = map (
            path:
            let
              fullPath = computeModulePath path;
              modVal = importFeatureFile path;
              isFeature = (modVal._type or "") == "feature";
              meta =
                if isFeature then
                  (modVal.meta or {
                    inherit (modVal)
                      requires
                      platforms
                      description
                      cascade
                      ;
                  }
                  )
                else
                  (modVal._meta or modVal.meta or null);
            in
            {
              file = path;
              path = fullPath;
              meta = meta;
              isFeature = isFeature;
              feature =
                if isFeature then
                  (
                    modVal
                    // {
                      path = fullPath;
                      file = path;
                    }
                  )
                else
                  null;
            }
          ) moduleFilesFiltered;

          modulesWithMetaList = filter (m: m.meta != null) modulesWithMeta;
          discoveredFeatures = filter (f: f != null) (map (m: m.feature) modulesWithMeta);

          extFeatures = if isList extFeaturesArg then extFeaturesArg else [ ];
          extFeaturesWithPaths = map (
            f:
            let
              path =
                f.path or (
                  if f ? name then
                    (if hasPrefix "home." f.name then f.name else "home." + f.name)
                  else
                    throw "Feature in private-extension must have path or name"
                );
            in
            f // { inherit path; }
          ) extFeatures;

          repoFeaturePaths = map (f: f.path) discoveredFeatures;
          extFeaturePaths = map (f: f.path) extFeaturesWithPaths;
          collisions = intersectLists repoFeaturePaths extFeaturePaths;
          _assert =
            assert assertMsg (
              collisions == [ ]
            ) "Colliding feature paths between repository and private-extension: ${toString collisions}";
            true;

          discoveredAndExtFeatures = discoveredFeatures ++ extFeaturesWithPaths;
          allFeaturePathSet = listToAttrs (
            map (f: {
              name = f.path;
              value = true;
            }) discoveredAndExtFeatures
          );
          missingDeps = concatMap (
            f:
            map (dep: "${f.path} -> ${dep}") (filter (dep: !(allFeaturePathSet ? ${dep})) (f.requires or [ ]))
          ) discoveredAndExtFeatures;
          _assertDeps =
            assert assertMsg (
              missingDeps == [ ]
            ) "Unknown feature paths in requires: ${concatStringsSep ", " missingDeps}";
            true;

          allFeatures =
            assert _assert;
            assert _assertDeps;
            discoveredAndExtFeatures;
        in
        {
          modules = modulesWithMetaList;
          allModules = modulesWithMeta;
          features = allFeatures;
          featureCatalog = allFeatures;
        };
      defaultRegistry = makeRegistry [ ];
    in
    defaultRegistry
    // {
      __functor = _: makeRegistry;
    };
  mkBoolOpt =
    default:
    mkOption {
      inherit default;
      type = bool;
      example = true;
    };

  recursiveDirs =
    dir:
    let
      files = filterAttrs (n: v: hasSuffix ".nix" n || v == "directory") (builtins.readDir dir);
    in
    (mapAttrs' (
      n: v:
      if v == "directory" && n != "dotfiles" then
        nameValuePair n (recursiveDirs "${toString dir}/${n}")
      else
        let
          name = removeSuffix ".nix" n;
        in
        nameValuePair name "${toString dir}/${n}"
    ))
      files;

  flattenModules =
    modules:
    (concatMap (
      x:
      if x == [ ] || x == "default" || x == "_default" || x == "dotfiles" then
        [ ]
      else if isAttrs modules.${x} then
        (flattenModules modules.${x})
      else
        [ modules.${x} ]
    ) (attrNames modules));

  # System module wrapper for systems/all, systems/darwin, systems/linux modules
  # - Uses systemAll/systemDarwin/systemLinux option namespace (not modules.*)
  # - Has platform restrictions built-in (no need for tags)
  # - Passes through special inputs (overlays, inputs, hardware, etc.)
  # - No automatic home-manager user routing (modules can do it manually)
  #
  # Usage:
  #   { lib, config, overlays, system, ... }@args:
  #   lib.my.mkSystemModuleV2 args {
  #     namespace = "all";  # "all" | "darwin" | "linux"
  #     description = "Common Nix settings";
  #     module = cfg: {
  #       nix.settings.experimental-features = [ "nix-command" "flakes" ];
  #     };
  #     # Optional: platform-specific config
  #     moduleLinux = cfg: { system.stateVersion = "25.11"; };
  #     moduleDarwin = cfg: { system.stateVersion = 5; };
  #     extraOptions = { foo = mkOption { ... }; };
  #   }
  mkSystemModuleV2 =
    args:
    {
      namespace, # "all" | "darwin" | "linux"
      description ? null,
      module ? (_: { }),
      moduleLinux ? null, # Linux-specific additions (for namespace = "all")
      moduleDarwin ? null, # Darwin-specific additions (for namespace = "all")
      moduleDisabled ? null, # Optional config applied when platformActive && !enabled
      cascade ? true, # Whether tier-level modules.system.<namespace>.enable activates unset module
      extraOptions ? { },
      imports ? [ ],
    }:
    let
      inherit (args) config system _modulePath;

      isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
      isLinux = system == "aarch64-linux" || system == "x86_64-linux";

      # Determine if this module should be active on this platform
      platformActive =
        if namespace == "all" then
          true
        else if namespace == "darwin" then
          isDarwin
        else if namespace == "linux" then
          isLinux
        else
          false;

      # Build option path from _modulePath
      # e.g., "modules.system.all.nix.settings" or "modules.system.darwin.homebrew"
      # _modulePath comes in as e.g., "systems.all.nix.settings"
      # We transform "systems.<platform>.*" -> "modules.system.<platform>.*"
      transformedPath =
        let
          parts = splitString "." _modulePath;
          # Check if path starts with "systems"
          startsWithSystems = (head parts) == "systems";
          # Get platform part (all/darwin/linux) and rest of path
          platformPart = if startsWithSystems then elemAt parts 1 else null;
          restParts = if startsWithSystems then drop 2 parts else tail parts;
        in
        if startsWithSystems then
          concatStringsSep "." (
            [
              "modules"
              "system"
              platformPart
            ]
            ++ restParts
          )
        else
          _modulePath;

      pathParts = splitString "." transformedPath;

      # Get module config lazily so modules can inspect cfg without strict foldl' cycles
      cfg = attrByPath pathParts { } config;

    in
    {
      inherit imports;

      options = setAttrByPath pathParts (
        {
          # Tri-state enable (null = inherit tier cascade, false = explicit opt-out, true = explicit enable)
          enable = mkOption {
            default = null;
            type = types.nullOr types.bool;
            description = description;
          };
        }
        // extraOptions
      );

      config =
        let
          # Tier-level cascade: modules.system.<namespace>.enable = true activates unset child modules
          # when cascade = true, while an explicit child enable = false opts out of the cascade.
          tierEnable = config.modules.system.${namespace}.enable or false;
          enabled =
            if (cfg.enable or null) != null then
              cfg.enable
            else if cascade then
              tierEnable
            else
              false;
        in
        mkMerge (
          [
            (mkIf (platformActive && enabled) (
              let
                # module can be attrset or function (cfg -> attrset)
                resolvedModule = if isFunction module then module cfg else module;

                # Platform-specific additions
                resolvedLinux =
                  if moduleLinux != null && isLinux then
                    (if isFunction moduleLinux then moduleLinux cfg else moduleLinux)
                  else
                    { };
                resolvedDarwin =
                  if moduleDarwin != null && isDarwin then
                    (if isFunction moduleDarwin then moduleDarwin cfg else moduleDarwin)
                  else
                    { };
              in
              mkMerge [
                resolvedModule
                resolvedLinux
                resolvedDarwin
              ]
            ))
          ]
          ++ optional (moduleDisabled != null) (
            mkIf (platformActive && !enabled) (
              if isFunction moduleDisabled then moduleDisabled cfg else moduleDisabled
            )
          )
        );
    };
}
