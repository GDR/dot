# Native Feature Descriptor and Compiler (mkFeature)
# Provides per-user Home Manager isolation, typed option trees, and two-stage system activation
{ lib, inputs ? { }, ... }:

let
  moduleRegistryHelper = import ./moduleRegistry.nix { inherit lib; };

  # Compute module path from file path
  # e.g., "/path/to/modules/home/cli/htop.nix" -> "home.cli.htop"
  # e.g., "/path/to/modules/home/cli/htop/htop.nix" -> "home.cli.htop" (dedup)
  computeModulePath = filePath:
    let
      pathStr = toString filePath;
      isModulePath = lib.hasInfix "modules/" pathStr;
      afterModules = lib.last (lib.splitString "modules/" pathStr);
      withoutNix = lib.removeSuffix ".nix" afterModules;
      parts = lib.splitString "/" withoutNix;
      fileName = lib.last parts;
      parentDir = if lib.length parts >= 2 then lib.elemAt parts (lib.length parts - 2) else null;
      dedupedParts =
        if parentDir == fileName
        then lib.init parts
        else parts;
      modulePath = lib.concatStringsSep "." dedupedParts;
    in
    if isModulePath then modulePath else null;

  # mkFeature: Pure declarative feature descriptor constructor
  mkFeature =
    { description ? null
    , platforms ? [ "linux" "darwin" ]
    , requires ? [ ]
    , extraOptions ? { }
    , dotfiles ? null
    , homeModule ? null
    , homeModuleLinux ? null
    , homeModuleDarwin ? null
    , nixosModule ? null
    , darwinModule ? null
    }:
    assert lib.assertMsg (lib.isList platforms) "mkFeature: platforms must be a list of strings";
    assert lib.assertMsg (lib.isList requires) "mkFeature: requires must be a list of strings";
    assert lib.assertMsg (lib.isAttrs extraOptions) "mkFeature: extraOptions must be an attribute set";
    assert lib.assertMsg (dotfiles == null || lib.isAttrs dotfiles) "mkFeature: dotfiles must be null or an attribute set";
    assert lib.assertMsg (homeModule == null || lib.isFunction homeModule || lib.isAttrs homeModule) "mkFeature: homeModule must be null, a function, or an attribute set";
    assert lib.assertMsg (homeModuleLinux == null || lib.isFunction homeModuleLinux || lib.isAttrs homeModuleLinux) "mkFeature: homeModuleLinux must be null, a function, or an attribute set";
    assert lib.assertMsg (homeModuleDarwin == null || lib.isFunction homeModuleDarwin || lib.isAttrs homeModuleDarwin) "mkFeature: homeModuleDarwin must be null, a function, or an attribute set";
    assert lib.assertMsg (nixosModule == null || lib.isFunction nixosModule || lib.isAttrs nixosModule) "mkFeature: nixosModule must be null, a function, or an attribute set";
    assert lib.assertMsg (darwinModule == null || lib.isFunction darwinModule || lib.isAttrs darwinModule) "mkFeature: darwinModule must be null, a function, or an attribute set";
    {
      _type = "feature";
      inherit description platforms requires extraOptions dotfiles
              homeModule homeModuleLinux homeModuleDarwin nixosModule darwinModule;
      meta = {
        inherit description platforms requires;
      };
    };

  # Generate strongly-typed option trees for categories and leaf features
  # Both options.modules.home.* and options.hostUsers.<user>.modules.home.* use this
  buildFeatureOptionTree = { featureCatalog ? [ ], knownModulePaths ? [ ] }:
    let
      featurePaths = map (f: lib.splitString "." f.path) featureCatalog;
      allPaths = (map (p: lib.splitString "." p) knownModulePaths) ++ featurePaths;
      categoryPrefixes = lib.unique (lib.concatMap (p:
        let len = lib.length p; in
        lib.genList (i: lib.take (i + 1) p) (len - 1)
      ) allPaths);

      isCategory = prefix: lib.any (c: c == prefix) categoryPrefixes;

      buildSubtree = prefix:
        let
          prefixLen = lib.length prefix;
          relevantPaths = lib.filter (p: (lib.length p > prefixLen) && (lib.take prefixLen p == prefix))
            (categoryPrefixes ++ featurePaths);
          childNames = lib.unique (map (p: lib.elemAt p prefixLen) relevantPaths);

          categoryOpt =
            if (prefixLen > 0 && isCategory prefix) then {
              enable = lib.mkOption {
                type = lib.types.nullOr lib.types.bool;
                default = null;
                description = "Enable ${lib.concatStringsSep "." prefix} modules";
              };
            } else { };

          matchingFeature = lib.findFirst (f: lib.splitString "." f.path == prefix) null featureCatalog;
          featureOpts =
            if matchingFeature != null then {
              enable = lib.mkOption {
                type = lib.types.nullOr lib.types.bool;
                default = null;
                description = matchingFeature.description or "Enable ${matchingFeature.path}";
              };
            }
            // (lib.optionalAttrs (matchingFeature.dotfiles != null) {
              dotfilesLive = lib.mkOption {
                type = lib.types.nullOr lib.types.bool;
                default = null;
                description = "Override dotfile symlink mode for ${matchingFeature.path} (true = live edit out-of-store, false = immutable nix store).";
              };
            })
            // (matchingFeature.extraOptions or { })
            else { };

          children = lib.listToAttrs (map (name: {
            inherit name;
            value = buildSubtree (prefix ++ [ name ]);
          }) childNames);
        in
        categoryOpt // featureOpts // children;
    in
    {
      home = buildSubtree [ "home" ];
    };

  # Check if a feature is enabled for a specific user:
  # 1. Walks from leaf to root in userModules: most specific non-null setting wins.
  # 2. If user setting is null, falls back to global config.modules hierarchy.
  # 3. If directly enabled, returns true.
  # 4. If user explicitly set enable = false, returns false (transitive requires cannot override user opt-out).
  # 5. Otherwise, checks per-user transitive requires via moduleRegistry.resolveDeps.
  isFeatureEnabledForUser =
    { config ? null
    , osConfig ? null
    , userName
    , featurePath ? null
    , modulePath ? null
    , featureCatalog ? null
    , modulesRegistry ? null
    , ...
    }:
    let
      cfg = if config != null then config else osConfig;
      path = if featurePath != null then featurePath else modulePath;
      pathParts = lib.splitString "." path;

      catalog =
        if featureCatalog != null then featureCatalog
        else if modulesRegistry != null then (modulesRegistry.features or modulesRegistry.featureCatalog or [ ])
        else if cfg ? _modulesRegistry && cfg._modulesRegistry != null then (cfg._modulesRegistry.features or cfg._modulesRegistry.featureCatalog or [ ])
        else [ ];

      prefixes = lib.genList (i: lib.take (i + 1) pathParts) (lib.length pathParts);
      revPrefixes = lib.reverseList prefixes;

      findSetting = modules:
        lib.foldl' (acc: prefix:
          if acc != null then acc
          else
            let
              sub = lib.foldl' (a: p: a.${p} or { }) modules prefix;
            in
            sub.enable or null
        ) null revPrefixes;

      userModules = cfg.hostUsers.${userName}.modules or { };
      globalModules = cfg.modules or { };

      userSetting = findSetting userModules;
      globalSetting = findSetting globalModules;

      directlyEnabled =
        if userSetting != null then userSetting
        else if globalSetting != null then globalSetting
        else false;
    in
    if directlyEnabled then true
    else if userSetting == false then false # User explicit opt-out wins over transitive requires
    else
      # Check transitive requirements
      let
        registryModules =
          if modulesRegistry != null then (modulesRegistry.modules or [ ])
          else if cfg ? _modulesRegistry && cfg._modulesRegistry != null then (cfg._modulesRegistry.modules or [ ])
          else [ ];

        moduleMap =
          (lib.listToAttrs (map (m: { name = m.path; value = m.meta or m; }) registryModules))
          // (lib.listToAttrs (map (f: { name = f.path; value = f; }) catalog));

        allKnownPaths = lib.attrNames moduleMap;

        isPathDirectlyEnabled = p:
          let
            pParts = lib.splitString "." p;
            pPrefixes = lib.genList (i: lib.take (i + 1) pParts) (lib.length pParts);
            pRevPrefixes = lib.reverseList pPrefixes;
            pFindSetting = modules:
              lib.foldl' (acc: prefix:
                if acc != null then acc
                else
                  let sub = lib.foldl' (a: part: a.${part} or { }) modules prefix; in
                  sub.enable or null
              ) null pRevPrefixes;
            uSet = pFindSetting userModules;
            gSet = pFindSetting globalModules;
          in
          if uSet != null then uSet
          else if gSet != null then gSet
          else false;

        directlyEnabledPaths = lib.filter (p: p != path && isPathDirectlyEnabled p) allKnownPaths;

        isRequired = lib.any (parentPath:
          let
            deps = moduleRegistryHelper.resolveDeps moduleMap parentPath [ ];
          in
          lib.elem path deps
        ) directlyEnabledPaths;
      in
      isRequired;

  # Resolve all active features for a user
  resolveUserFeatures =
    { osConfig
    , userName
    , userCfg
    , featureCatalog ? [ ]
    , modulesRegistry ? null
    , hostPlatform ? (
        let
          sys = osConfig.nixpkgs.system or "";
        in
        if lib.hasSuffix "-darwin" sys || (osConfig ? system && osConfig.system ? primaryUser) then "darwin"
        else "linux"
      )
    }:
    let
      catalog =
        if featureCatalog != [ ] then featureCatalog
        else if modulesRegistry != null then (modulesRegistry.features or modulesRegistry.featureCatalog or [ ])
        else if osConfig ? _modulesRegistry && osConfig._modulesRegistry != null then (osConfig._modulesRegistry.features or osConfig._modulesRegistry.featureCatalog or [ ])
        else [ ];
    in
    lib.filter (f:
      (lib.elem hostPlatform f.platforms)
      && isFeatureEnabledForUser {
        config = osConfig;
        inherit userName modulesRegistry;
        featurePath = f.path;
        featureCatalog = catalog;
      }
    ) catalog;

  # Single-user dotfiles compilation (scoped strictly to the user who enabled the feature)
  compileUserDotfiles =
    { osConfig
    , feature
    , featureCfg
    , userName
    , self ? null
    }:
    if feature.dotfiles == null then { }
    else
      let
        dotfiles = feature.dotfiles;
        path = dotfiles.path;
        source = dotfiles.source;
        target = dotfiles.target or null;

        isLive =
          if (featureCfg.dotfilesLive or null) != null then featureCfg.dotfilesLive
          else if (dotfiles.live or null) != null then dotfiles.live
          else (osConfig.dotfiles.live or false);

        targetPath = if target != null then target else "~/.config/${path}";
        isConfigDir = lib.hasPrefix "~/.config/" targetPath || lib.hasPrefix ".config/" targetPath;
        configPath =
          if isConfigDir then
            let withoutTilde = lib.removePrefix "~/.config/" targetPath; in
            lib.removePrefix ".config/" withoutTilde
          else null;

        homePath =
          if !isConfigDir then
            if lib.hasPrefix "~/" targetPath then lib.removePrefix "~/" targetPath
            else targetPath
          else null;
      in
      { config, lib, pkgs, ... }:
      let
        isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
        defaultRepoPath =
          if isDarwin then "/Users/${userName}/dot"
          else "/home/${userName}/dot";
        envDotfilesDir = osConfig.environment.variables.DOTFILES_DIR or null;
        repoPath =
          if envDotfilesDir != null
             && (lib.hasPrefix "/home/${userName}/" envDotfilesDir || lib.hasPrefix "/Users/${userName}/" envDotfilesDir)
          then envDotfilesDir
          else defaultRepoPath;

        sourcePath =
          if isLive then "${repoPath}/${source}"
          else if self != null then "${self}/${source}"
          else throw "self must be passed to compileUserDotfiles for Nix store dotfiles mode.";

        symlink =
          if isLive then config.lib.file.mkOutOfStoreSymlink sourcePath
          else sourcePath;
      in
      if isConfigDir then {
        xdg.configFile.${configPath}.source = symlink;
      } else {
        home.file.${homePath}.source = symlink;
      };

  # Dynamic per-user Home Manager module compilation
  # Compiles each user's enabled features into native Home Manager module imports
  compileUserHomeModules =
    { osConfig
    , userName
    , userCfg
    , featureCatalog ? [ ]
    , self ? null
    , inputs ? { }
    , modulesRegistry ? null
    }:
    let
      enabledFeatures = resolveUserFeatures {
        inherit osConfig userName userCfg featureCatalog modulesRegistry;
      };

      compileSingleFeature = feature:
        let
          pathParts = lib.splitString "." feature.path;
          globalCfg = lib.foldl' (acc: p: acc.${p} or { }) (osConfig.modules or { }) pathParts;
          userRawCfg = lib.foldl' (acc: p: acc.${p} or { }) (userCfg.modules or { }) pathParts;
          featureCfg = lib.recursiveUpdate globalCfg userRawCfg;

          dotfilesConfig = compileUserDotfiles {
            inherit osConfig feature featureCfg userName self;
          };
        in
        { config, pkgs, lib, ... }@hmArgs:
        let
          featureArgs = hmArgs // {
            inherit featureCfg userName osConfig;
          };
          isLinux = pkgs.stdenv.hostPlatform.isLinux;
          isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
        in
        lib.mkMerge [
          (if feature.homeModule != null then
            (if lib.isFunction feature.homeModule then feature.homeModule featureArgs else feature.homeModule)
           else { })
          (if isLinux && feature.homeModuleLinux != null then
            (if lib.isFunction feature.homeModuleLinux then feature.homeModuleLinux featureArgs else feature.homeModuleLinux)
           else { })
          (if isDarwin && feature.homeModuleDarwin != null then
            (if lib.isFunction feature.homeModuleDarwin then feature.homeModuleDarwin featureArgs else feature.homeModuleDarwin)
           else { })
          (if lib.isFunction dotfilesConfig then dotfilesConfig hmArgs else dotfilesConfig)
        ];
    in
    map compileSingleFeature enabledFeatures;

  # Two-stage system activation
  # Evaluates nixosModule / darwinModule once at machine level when selectedUsers != [] or globally enabled
  compileSystemFeatureModules =
    { config
    , pkgs
    , lib
    , system
    , featureCatalog ? [ ]
    , modulesRegistry ? null
    }:
    let
      isLinux = system == "x86_64-linux" || system == "aarch64-linux";
      isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
      allUserNames = lib.attrNames (lib.filterAttrs (_: u: u.enable) (config.hostUsers or { }));

      catalog =
        if featureCatalog != [ ] then featureCatalog
        else if modulesRegistry != null then (modulesRegistry.features or modulesRegistry.featureCatalog or [ ])
        else if config ? _modulesRegistry && config._modulesRegistry != null then (config._modulesRegistry.features or config._modulesRegistry.featureCatalog or [ ])
        else [ ];
    in
    lib.mkMerge (map (feature:
      let
        pathParts = lib.splitString "." feature.path;
        globalCfg = lib.foldl' (acc: p: acc.${p} or { }) (config.modules or { }) pathParts;

        selectedUsers = lib.filter (u:
          isFeatureEnabledForUser {
            inherit config system modulesRegistry;
            userName = u;
            featurePath = feature.path;
            featureCatalog = catalog;
          }
        ) allUserNames;

        isGloballyEnabled = (globalCfg.enable or null) == true;
        shouldActivate = (selectedUsers != [ ]) || isGloballyEnabled;

        systemArgs = {
          inherit config pkgs lib system selectedUsers;
          featureCfg = globalCfg;
        };
      in
      lib.mkIf shouldActivate (
        lib.mkMerge [
          (if isLinux && feature.nixosModule != null then
            (if lib.isFunction feature.nixosModule then feature.nixosModule systemArgs else feature.nixosModule)
           else { })
          (if isDarwin && feature.darwinModule != null then
            (if lib.isFunction feature.darwinModule then feature.darwinModule systemArgs else feature.darwinModule)
           else { })
        ]
      )
    ) catalog);

in
{
  inherit
    computeModulePath
    mkFeature
    buildFeatureOptionTree
    isFeatureEnabledForUser
    resolveUserFeatures
    compileUserDotfiles
    compileUserHomeModules
    compileSystemFeatureModules;
}
