{ lib, inputs, ... }: with lib; with types; rec {
  # Import module registry functions
  moduleRegistry = import ./moduleRegistry.nix { inherit lib; };

  # Native feature compiler and mkFeature descriptor
  features = import ./features.nix { inherit lib inputs; };
  inherit (features)
    computeModulePath
    mkFeature
    buildFeatureOptionTree
    isFeatureEnabledForUser
    resolveUserFeatures
    compileUserDotfiles
    compileUserHomeModules
    compileSystemFeatureModules;

  mkUserDotfilesConfig = compileUserDotfiles;

  # ── Theme system ─────────────────────────────────────────────────────────
  # Theme registry: lib.my.themes.getTheme "rose-pine-moon"
  themes = import ./themes { inherit lib; };

  # Active theme: set via config.theme.name in host config.
  # Usage in any module: lib.my.getTheme config
  # Returns the full theme attrset (colors, roles, terminal, fonts).
  getTheme = config:
    let
      name = config.theme.name or "rose-pine-moon";
    in
    themes.getTheme name;

  # Factory function to create flake helpers
  # Call with: lib.my.mkFlakeHelpers { inherit self overlays; }
  # Returns: { mkDarwinConfiguration, mkNixosConfiguration, ... }
  mkFlakeHelpers = { self, overlays }:
    import ./flakeHelpers.nix { inherit inputs lib self overlays; };

  # Re-export module registry functions for convenience
  pathToConfigParts = moduleRegistry.pathToConfigParts;

  # Merge a list of profile attrsets into one.
  # Each profile may declare: userModules, system.all, system.linux, system.darwin.
  # Uses recursiveUpdate so nested enables from different profiles don't clobber each other.
  # Usage:
  #   profiles = lib.my.mergeProfiles [
  #     (import ../../profiles/developer.nix)
  #     (import ../../profiles/desktop.nix)
  #   ];
  #   hostUsers.x.modules = lib.recursiveUpdate profiles.userModules { home.browsers.vivaldi.enable = true; };
  #   modules.system.all   = profiles.system.all   // { sops.enable = true; };
  #   modules.system.linux = profiles.system.linux // { graphics.nvidia.enable = true; };
  mergeProfiles = profiles:
    foldl
      (acc: p: {
        userModules = recursiveUpdate (acc.userModules or { }) (p.userModules or { });
        system = {
          all = recursiveUpdate (acc.system.all or { }) (p.system.all or { });
          linux = recursiveUpdate (acc.system.linux or { }) (p.system.linux or { });
          darwin = recursiveUpdate (acc.system.darwin or { }) (p.system.darwin or { });
        };
      })
      { }
      profiles;

  # Dummy specialArgs for metadata extraction — used by both tryImportMeta and
  # wrapModuleFile (see flakeHelpers.nix). Add new specialArgs here so both
  # sites stay in sync automatically.
  dummySpecialArgs = {
    config = { };
    options = { };
    pkgs = { };
    system = "x86_64-linux";
    inherit inputs;
    self = null;
    hardware = null;
    overlays = { };
    modulesRegistry = null;
    _modulePath = "";
  };

  # Build module registry from a directory
  # This scans modules and extracts metadata, returning a registry structure
  buildModuleRegistry = modulesDir: prefix:
    let
      makeRegistry = extFeaturesArg:
        let
          moduleTree = recursiveDirs modulesDir;
          moduleFiles = flattenModules moduleTree;

          # Filter out tags.nix and default.nix
          moduleFilesFiltered = filter
            (path:
              ! hasSuffix "tags.nix" path &&
              ! hasSuffix "default.nix" path
            )
            moduleFiles;

          libWithMy = lib // { inherit (lib) my; };

          tryImportFile = path:
            let
              fullPath = computeModulePath path;
              imported = import path;
              evalResult = builtins.tryEval (
                if isFunction imported
                then imported (dummySpecialArgs // { lib = libWithMy; _modulePath = fullPath; })
                else imported
              );
            in
            if evalResult.success then
              evalResult.value
            else
              let _ = builtins.trace "Warning: Failed to import ${toString path}: ${toString evalResult.value}" null; in null;

          modulesWithMeta = map
            (path:
              let
                fullPath = computeModulePath path;
                modVal = tryImportFile path;
                isFeature = (modVal._type or "") == "feature";
                meta =
                  if isFeature then
                    (modVal.meta or { inherit (modVal) requires platforms description; })
                  else
                    (modVal._meta or modVal.meta or null);
              in
              {
                file = path;
                path = fullPath;
                meta = meta;
                isFeature = isFeature;
                feature = if isFeature then (modVal // { path = fullPath; file = path; }) else null;
              }
            )
            moduleFilesFiltered;

          modulesWithMetaList = filter (m: m.meta != null) modulesWithMeta;
          discoveredFeatures = filter (f: f != null) (map (m: m.feature) modulesWithMeta);

          extFeatures = if isList extFeaturesArg then extFeaturesArg else [ ];
          extFeaturesWithPaths = map
            (f:
              let
                path = if f ? path then f.path else (if f ? name then (if hasPrefix "home." f.name then f.name else "home." + f.name) else throw "Feature in private-extension must have path or name");
              in
              f // { inherit path; }
            )
            extFeatures;

          repoFeaturePaths = map (f: f.path) discoveredFeatures;
          extFeaturePaths = map (f: f.path) extFeaturesWithPaths;
          collisions = intersectLists repoFeaturePaths extFeaturePaths;
          _assert = assert assertMsg (collisions == [ ])
            "Colliding feature paths between repository and private-extension: ${toString collisions}"; true;

          allFeatures = assert _assert; discoveredFeatures ++ extFeaturesWithPaths;
        in
        {
          modules = modulesWithMetaList;
          allModules = modulesWithMeta;
          features = allFeatures;
          featureCatalog = allFeatures;
        };
      defaultRegistry = makeRegistry [ ];
    in
    defaultRegistry // {
      __functor = self: extFeatures: makeRegistry extFeatures;
    };
  mkBoolOpt = default:
    mkOption {
      inherit default;
      type = bool;
      example = true;
    };

  recursiveDirs = dir:
    let files = filterAttrs (n: v: hasSuffix ".nix" n || v == "directory") (builtins.readDir dir); in (mapAttrs'
      (n: v:
        if v == "directory" && n != "dotfiles" then nameValuePair n (recursiveDirs "${toString dir}/${n}")
        else
          let name = removeSuffix ".nix" n;
          in nameValuePair name "${toString dir}/${n}"
      )
    ) files;

  flattenModules = modules: (
    concatMap
      (x:
        if x == [ ] || x == "default" || x == "_default" || x == "dotfiles" then [ ]
        else if isAttrs modules.${x} then (flattenModules modules.${x})
        else [ modules.${x} ]
      )
      (attrNames modules)
  );

  filterPrefix = prefix: files:
    builtins.filter (file: builtins.hasPrefix prefix (builtins.basename file)) files;

  # Helper to create users.users attribute set from list of usernames

  # Helper to derive config accessor from module path
  # Usage:
  #   let mod = lib.my.modulePath [ "home" "browsers" "firefox" ] config;
  #   in { options.modules.home.browsers.firefox = ...; config = mkIf mod.cfg.enable ...; }
  modulePath = pathParts: config:
    let
      cfgAccessor = foldl (acc: part: acc.${part}) config.modules pathParts;
    in
    {
      cfg = cfgAccessor;
    };

  # Check if a module should be enabled based on hierarchical path enables
  # A module is enabled if:
  #   - Its own .enable is true (modules.home.browsers.vivaldi.enable)
  #   - OR any parent path .enable is true (modules.home.browsers.enable, modules.home.enable)
  #   - OR any user has it enabled via hostUsers.<user>.modules.<path>.enable
  #   - OR any explicitly-enabled module lists this path in its requires (auto-dep)
  #
  # Usage (inside config block):
  #   shouldEnable = lib.my.shouldEnableModule {
  #     inherit config modulesRegistry;
  #     modulePath = "home.media.vlc";
  #   };

  # Raw enable check — no cascade, no requires. Used internally when resolving
  # requires chains to avoid circular evaluation.
  isExplicitlyEnabled = { config, modulePath }:
    let
      pathParts = splitString "." modulePath;
      generatePaths = parts:
        let indices = genList (i: i + 1) (length parts);
        in map (i: take i parts) indices;
      allPaths = generatePaths pathParts;
      checkPathEnable = parts:
        (foldl' (acc: part: acc.${part} or { }) config.modules parts).enable or false;
      anyGlobal = any checkPathEnable allPaths;
      enabledUsers = filterAttrs (_: u: u.enable or false) (config.hostUsers or { });
      checkUserPath = userModules: parts:
        (foldl' (acc: part: acc.${part} or { }) userModules parts).enable or false;
      anyUser = any
        (u: any (checkUserPath (u.modules or { })) allPaths)
        (attrValues enabledUsers);
    in
    anyGlobal || anyUser;

  shouldEnableModuleForUser = { config, userName, modulePath ? null, featurePath ? null, modulesRegistry ? null }:
    isFeatureEnabledForUser {
      inherit config userName modulesRegistry;
      featurePath = if featurePath != null then featurePath else modulePath;
    };

  shouldEnableModule = { config, modulePath, moduleTags ? [ ], modulesRegistry ? null }:
    let
      usersWithMod = getUsersWithModule { inherit config modulePath modulesRegistry; };
      pathParts = splitString "." modulePath;
      cfg = foldl' (acc: part: acc.${part} or { }) (config.modules or { }) pathParts;
      isGloballyEnabled = (cfg.enable or false) == true;
    in
    isGloballyEnabled || (usersWithMod != { });

  # Get list of users who have a module enabled (via any path level)
  # Usage: usersWithModule = lib.my.getUsersWithModule { inherit config modulePath; };
  getUsersWithModule = { config, modulePath, moduleTags ? [ ], modulesRegistry ? null }:
    let
      enabledUsers = filterAttrs (name: ucfg: ucfg.enable or false) (config.hostUsers or { });
    in
    filterAttrs
      (userName: _:
        isFeatureEnabledForUser {
          inherit config userName modulePath modulesRegistry;
        }
      )
      enabledUsers;

  # Get list of usernames who have a module enabled (convenience wrapper)
  # Usage: usernames = lib.my.getUsersWithModuleNames { inherit config _modulePath; };
  # Returns: [ "user1" "user2" ] - list of usernames
  getUsersWithModuleNames = { config, modulePath ? null, _modulePath ? null, moduleTags ? [ ], modulesRegistry ? null }:
    let
      # Support both modulePath and _modulePath (from args)
      path = if _modulePath != null then _modulePath else modulePath;
      usersWithModule = getUsersWithModule { inherit config moduleTags modulesRegistry; modulePath = path; };
    in
    attrNames usersWithModule;

  # Create symlink to repo dotfiles for all enabled users
  # Create symlinks to repo dotfiles for all enabled users
  # Modes:
  #   - live = true (Development / Live mode): creates out-of-store symlinks directly to repo on disk ($DOTFILES_DIR).
  #     Changes apply immediately without nixos-rebuild switch.
  #   - live = false (Settled / Store mode): copies files into the Nix Store ($self/source).
  #     Store paths are captured in NixOS / Home Manager generations, enabling GRUB / generation rollbacks
  #     to restore exact historical dotfile revisions.
  # Usage:
  #   config.home-manager.users = lib.my.mkDotfilesSymlink {
  #     inherit config self;
  #     path = "ghostty";                                    # used as fallback if target not specified
  #     source = "modules/home/terminal/ghostty/dotfiles";  # relative path in repo
  #     target = "~/.config/ghostty";                        # explicit target path (defaults to ~/.config/${path})
  #     live = true;                                         # optional mode override (defaults to config.dotfiles.live)
  #   };
  mkDotfilesSymlink = { config, self, path, source, target ? null, live ? false }:
    let
      isLive = live;

      enabledUsers = filterAttrs (_: u: u.enable) (config.hostUsers or { });

      # Target path calculation: if not specified, default to ~/.config/${path}
      targetPath = if target != null then target else "~/.config/${path}";

      # Parse target path to determine if it's in ~/.config or elsewhere
      # Handle both ~/.config/ and .config/ prefixes
      isConfigDir = hasPrefix "~/.config/" targetPath || hasPrefix ".config/" targetPath;
      configPath =
        if isConfigDir then
          let
            withoutTilde = removePrefix "~/.config/" targetPath;
          in
          removePrefix ".config/" withoutTilde
        else null;

      # For non-config paths, extract the path relative to home
      # If it doesn't start with ~/, treat it as relative to home
      homePath =
        if !isConfigDir then
          if hasPrefix "~/" targetPath then
            removePrefix "~/" targetPath
          else
            targetPath
        else null;

      sourcePath =
        if isLive then
          let
            repoPath = config.environment.variables.DOTFILES_DIR or
              (throw ''
                DOTFILES_DIR is not set. Add it to your host config:
                  environment.variables.DOTFILES_DIR = "/home/<user>/path/to/dot";
                This is required for live-editable dotfile symlinks.
              '');
          in
          "${repoPath}/${source}"
        else
          if self != null then
            "${self}/${source}"
          else
            throw "self must be passed to mkDotfilesSymlink for Nix store dotfiles mode.";
    in
    mapAttrs
      (name: _:
        if isConfigDir then {
          xdg.configFile.${configPath}.source =
            if isLive then
              config.home-manager.users.${name}.lib.file.mkOutOfStoreSymlink sourcePath
            else
              sourcePath;
        } else {
          home.file.${homePath}.source =
            if isLive then
              config.home-manager.users.${name}.lib.file.mkOutOfStoreSymlink sourcePath
            else
              sourcePath;
        }
      )
      enabledUsers;

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
  mkSystemModuleV2 = args:
    { namespace  # "all" | "darwin" | "linux"
    , description ? null
    , module ? (_: { })
    , moduleLinux ? null  # Linux-specific additions (for namespace = "all")
    , moduleDarwin ? null  # Darwin-specific additions (for namespace = "all")
    , extraOptions ? { }
    , imports ? [ ]
    }:
    let
      inherit (args) config system _modulePath;

      isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
      isLinux = system == "aarch64-linux" || system == "x86_64-linux";

      # Determine if this module should be active on this platform
      platformActive =
        if namespace == "all" then true
        else if namespace == "darwin" then isDarwin
        else if namespace == "linux" then isLinux
        else false;

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
          concatStringsSep "." ([ "modules" "system" platformPart ] ++ restParts)
        else _modulePath;

      pathParts = splitString "." transformedPath;

      # Get module config
      cfg = foldl' (acc: part: acc.${part} or { }) config pathParts;

    in
    {
      inherit imports;

      options = setAttrByPath pathParts ({
        enable = mkOption {
          default = false;
          type = bool;
          description = description;
        };
      } // extraOptions);

      config =
        let
          # Tier-level cascade: modules.system.linux.enable = true activates all linux modules
          tierEnable = config.modules.system.${namespace}.enable or false;
        in
        mkIf (platformActive && ((cfg.enable or false) || tierEnable)) (
          let
            # module can be attrset or function (cfg -> attrset)
            resolvedModule = if isFunction module then module cfg else module;

            # Platform-specific additions
            resolvedLinux =
              if moduleLinux != null && isLinux then
                (if isFunction moduleLinux then moduleLinux cfg else moduleLinux)
              else { };
            resolvedDarwin =
              if moduleDarwin != null && isDarwin then
                (if isFunction moduleDarwin then moduleDarwin cfg else moduleDarwin)
              else { };
          in
          mkMerge [
            resolvedModule
            resolvedLinux
            resolvedDarwin
          ]
        );
    };
}
