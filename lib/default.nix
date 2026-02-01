{ lib, inputs, ... }: with lib; with types; rec {
  # Import module registry functions
  moduleRegistry = import ./moduleRegistry.nix { inherit lib; };

  # Factory function to create flake helpers
  # Call with: lib.my.mkFlakeHelpers { inherit self overlays; }
  # Returns: { mkDarwinConfiguration, mkNixosConfiguration, ... }
  mkFlakeHelpers = { self, overlays }:
    import ./flakeHelpers.nix { inherit inputs lib self overlays; };

  # Re-export module registry functions for convenience
  pathToConfigParts = moduleRegistry.pathToConfigParts;

  # Build module registry from a directory
  # This scans modules and extracts metadata, returning a registry structure
  buildModuleRegistry = modulesDir: prefix:
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

      # Try to extract metadata from modules
      # Use the lib.my that's already available (passed from flake)
      tryImportMeta = path:
        let
          # lib.my should already be available since this is called from lib.my context
          libWithMy = lib // { inherit (lib) my; };
          moduleResult = builtins.tryEval (import path {
            config = { };
            options = { };
            pkgs = { };
            lib = libWithMy;
            system = "x86_64-linux";
          });
        in
        if moduleResult.success then
          (moduleResult.value._meta or moduleResult.value.meta or null)
        else null;

      modulesWithMeta = map
        (path:
          let
            relativePath = removePrefix "./" (removeSuffix ".nix" path);
            fullPath = prefix + "." + (replaceStrings [ "/" ] [ "." ] relativePath);
            meta = tryImportMeta path;
          in
          {
            file = path;
            path = fullPath;
            meta = meta;
          }
        )
        moduleFilesFiltered;

      modulesWithMetaList = filter (m: m.meta != null) modulesWithMeta;
    in
    {
      modules = modulesWithMetaList;
      allModules = modulesWithMeta;
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

  # mkModule: Creates platform-aware config that routes user config to home-manager.users
  # Usage in modules:
  #   let mkModule = lib.my.mkModule system config; in
  #   mkIf shouldEnable (mkModule {
  #     nixosSystems.home.packages = [ pkgs.htop ];     # → home-manager.users.*.home.packages
  #     nixosSystems.programs.chromium.enable = true;  # → home-manager.users.*.programs.chromium
  #     nixosSystems.services.foo.enable = true;       # System-level config (stays as-is)
  #     darwinSystems.homebrew.casks = [ "htop" ];
  #   })
  # Helper to create users.users attribute set from list of usernames
  # Usage:
  #   users.users = lib.my.mkUsersAttrs enabledUsernames (username: { shell = pkgs.zsh; });
  #   users.users = lib.my.mkUsersAttrs enabledUsernames (username: { extraGroups = [ "docker" ]; });
  mkUsersAttrs = usernames: fn:
    listToAttrs (map
      (username: {
        name = username;
        value = fn username;
      })
      usernames);

  # Home-manager attrs (home, programs, xdg, services, etc.) are routed to all enabled users
  mkModule = system: config: cfg:
    let
      isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
      isLinux = system == "aarch64-linux" || system == "x86_64-linux";

      rawConfig =
        if isLinux then (cfg.nixosSystems or { }) // (cfg.allSystems or { })
        else if isDarwin then (cfg.darwinSystems or { }) // (cfg.allSystems or { })
        else { };

      # Home-manager user-level attributes (routed to home-manager.users.*)
      # Note: systemd, gtk, qt, dconf, wayland, xresources, xsession are Linux-only
      hmUserAttrsBase = [ "home" "programs" "xdg" "services" "accounts" "fonts" "manual" "news" "nix" "targets" ];
      hmUserAttrsLinux = [ "systemd" "gtk" "qt" "dconf" "wayland" "xresources" "xsession" ];
      hmUserAttrs = hmUserAttrsBase ++ (if isLinux then hmUserAttrsLinux else [ ]);

      # Extract home-manager attrs from config
      userConfig = filterAttrs (name: _: elem name hmUserAttrs) rawConfig;
      hasUserConfig = userConfig != { };

      # Remove home-manager attrs from system config
      systemConfig = filterAttrs (name: _: !(elem name hmUserAttrs)) rawConfig;

      # Get enabled users for home config routing
      enabledUsers = filterAttrs (_: u: u.enable) (config.hostUsers or { });
    in
    systemConfig // (optionalAttrs hasUserConfig {
      home-manager.users = mapAttrs (name: _: userConfig) enabledUsers;
    });

  # mkModuleConfig: Combines mkModule + optional dotfiles symlink
  # Usage:
  #   config = mkIf shouldEnable (lib.my.mkModuleConfig {
  #     inherit system config self;
  #     module = {
  #       nixosSystems.home.packages = [ pkgs.ghostty ];
  #       darwinSystems.homebrew.casks = [ "ghostty" ];
  #     };
  #     dotfiles = { path = "ghostty"; source = "modules_v2/.../dotfiles"; };
  #   });
  mkModuleConfig = { system, config, self ? null, module, dotfiles ? null }:
    mkMerge [
      (mkModule system config module)
      (optionalAttrs (dotfiles != null && self != null) {
        home-manager.users = mkDotfilesSymlink {
          inherit config self;
          inherit (dotfiles) path source;
        };
      })
    ];

  # Module metadata structure (for registry/discovery)
  mkModuleMeta =
    { requires ? [ ]
    , # List of module paths: ["home.shell.git", "home.utils.bazel"]
      platforms ? [ "linux" "darwin" ]
    , scope ? "user"
    , # "system" = system services/drivers, "user" = home.packages
      description ? null
    }: {
      inherit requires platforms scope description;
    };

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
  #
  # Usage (inside config block):
  #   shouldEnable = lib.my.shouldEnableModule {
  #     inherit config;
  #     modulePath = "home.media.vlc";
  #   };
  shouldEnableModule = { config, modulePath, moduleTags ? [ ] }:
    let
      pathParts = splitString "." modulePath;

      # Generate all parent paths: ["home", "home.browsers", "home.browsers.vivaldi"]
      # We check .enable on each of these
      generatePaths = parts:
        let
          indices = genList (i: i + 1) (length parts);
        in
        map (i: take i parts) indices;

      allPaths = generatePaths pathParts;

      # Check if any path (including parents) has .enable = true in config.modules
      checkPathEnable = parts:
        let
          cfg = foldl' (acc: part: acc.${part} or { }) config.modules parts;
        in
          cfg.enable or false;

      anyGlobalPathEnabled = any checkPathEnable allPaths;

      # Per-user check: same logic but in hostUsers.<user>.modules
      enabledUsers = filterAttrs (name: ucfg: ucfg.enable or false) (config.hostUsers or { });

      checkUserPathEnable = userModules: parts:
        let
          cfg = foldl' (acc: part: acc.${part} or { }) userModules parts;
        in
          cfg.enable or false;

      anyUserHasPathEnabled = any
        (ucfg:
          let
            userModules = ucfg.modules or { };
          in
          any (path: checkUserPathEnable userModules path) allPaths
        )
        (attrValues enabledUsers);
    in
    anyGlobalPathEnabled || anyUserHasPathEnabled;

  # Get list of users who have a module enabled (via any path level)
  # Usage: usersWithModule = lib.my.getUsersWithModule { inherit config modulePath; };
  getUsersWithModule = { config, modulePath, moduleTags ? [ ] }:
    let
      pathParts = splitString "." modulePath;
      generatePaths = parts:
        let
          indices = genList (i: i + 1) (length parts);
        in
        map (i: take i parts) indices;
      allPaths = generatePaths pathParts;

      enabledUsers = filterAttrs (name: ucfg: ucfg.enable or false) (config.hostUsers or { });

      checkUserPathEnable = userModules: parts:
        let
          cfg = foldl' (acc: part: acc.${part} or { }) userModules parts;
        in
          cfg.enable or false;
    in
    filterAttrs
      (name: ucfg:
        let
          userModules = ucfg.modules or { };
        in
        any (path: checkUserPathEnable userModules path) allPaths
      )
      enabledUsers;

  # Create symlink to repo dotfiles for all enabled users
  # This allows editing config files without rebuild
  # Usage:
  #   config.home-manager.users = lib.my.mkDotfilesSymlink {
  #     inherit config self;
  #     path = "ghostty";                                    # used as fallback if target not specified
  #     source = "modules_v2/home/terminal/ghostty/dotfiles";  # relative path in repo
  #     target = "~/.config/ghostty";                        # explicit target path (defaults to ~/.config/${path})
  #   };
  mkDotfilesSymlink = { config, self, path, source, target ? null }:
    let
      enabledUsers = filterAttrs (_: u: u.enable) (config.hostUsers or { });
      # Use self.outPath to get actual repo path (not nix store)
      # In flakes, self.outPath should point to the source directory
      repoPath = self.outPath;
      fullPath = "${repoPath}/${source}";

      # Determine target path: if not specified, default to ~/.config/${path}
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
    in
    mapAttrs
      (name: _:
        if isConfigDir then {
          xdg.configFile.${configPath}.source =
            config.home-manager.users.${name}.lib.file.mkOutOfStoreSymlink fullPath;
        } else {
          home.file.${homePath}.source =
            config.home-manager.users.${name}.lib.file.mkOutOfStoreSymlink fullPath;
        }
      )
      enabledUsers;

  # Generate module options from path string
  # Usage:
  #   options = lib.my.mkModuleOptions "home.core.htop" {
  #     enable = mkOption { default = false; type = types.bool; };
  #   };
  # Returns: { modules.home.core.htop = { enable = ...; }; }
  mkModuleOptions = modulePath: opts:
    let
      pathParts = splitString "." modulePath;
    in
    { modules = setAttrByPath pathParts opts; };

  # Complete module wrapper for modules_v2
  # Returns { meta, options, config, imports? } - the entire module structure
  #
  # Modules are enabled hierarchically:
  #   - modules.home.browsers.vivaldi.enable = true  (specific module)
  #   - modules.home.browsers.enable = true          (all browsers)
  #   - modules.home.enable = true                   (all home modules)
  #   - hostUsers.<user>.modules.home.browsers.enable = true (per-user)
  #
  # Usage:
  #   { lib, pkgs, ... }@args:
  #   lib.my.mkModuleV2 args {
  #     description = "Ghostty terminal emulator";
  #     module = {
  #       nixosSystems.home.packages = [ pkgs.ghostty ];
  #       darwinSystems.homebrew.casks = [ "ghostty" ];
  #     };
  #     dotfiles = {
  #       path = "ghostty";
  #       source = "modules_v2/home/terminal/ghostty/dotfiles";
  #     };
  #     extraOptions = {
  #       showHostname = mkOption { default = true; type = types.bool; };
  #     };
  #   }
  # Module sections: allSystems, nixosSystems, darwinSystems
  # home.* config is automatically routed to all enabled hostUsers
  mkModuleV2 = args:
    { platforms ? [ "linux" "darwin" ]
    , requires ? [ ]  # List of module paths this module depends on
    , description ? null
    , module ? { }
    , systemModule ? { }
    , dotfiles ? null
    , extraOptions ? { }
    , imports ? [ ]
    }:
    let
      inherit (args) config pkgs system _modulePath;
      inherit (args) lib;
      self = args.self or null;
      modulePath = _modulePath;

      # Get module config (for accessing options)
      pathParts = splitString "." modulePath;
      cfg = foldl' (acc: part: acc.${part} or { }) config.modules pathParts;

      isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
      isLinux = system == "aarch64-linux" || system == "x86_64-linux";

      # Get enabled users for home config routing (needed for shouldEnable check)
      enabledUsers = filterAttrs (_: u: u.enable) (config.hostUsers or { });
    in
    {
      inherit imports;

      meta = mkModuleMeta {
        inherit requires platforms description;
      };

      options = mkModuleOptions modulePath ({
        enable = mkOption {
          default = false;
          type = bool;
          description = description;
        };
      } // extraOptions);

      config =
        let
          shouldEnable = shouldEnableModule { inherit config modulePath; };
        in
        mkIf shouldEnable (
          let
            # module can be attrset or function (cfg -> attrset)
            resolvedModule = if isFunction module then module cfg else module;

            rawConfig =
              if isLinux then (resolvedModule.nixosSystems or { }) // (resolvedModule.allSystems or { })
              else if isDarwin then (resolvedModule.darwinSystems or { }) // (resolvedModule.allSystems or { })
              else { };

            # Home-manager user-level attributes (routed to home-manager.users.*)
            # Note: systemd, gtk, qt, dconf, wayland, xresources, xsession are Linux-only
            hmUserAttrsBase = [ "home" "programs" "xdg" "services" "accounts" "fonts" "manual" "news" "nix" "targets" ];
            hmUserAttrsLinux = [ "systemd" "gtk" "qt" "dconf" "wayland" "xresources" "xsession" ];
            hmUserAttrs = hmUserAttrsBase ++ (if isLinux then hmUserAttrsLinux else [ ]);

            # Extract home-manager attrs from config
            userConfig = filterAttrs (name: _: elem name hmUserAttrs) rawConfig;
            hasUserConfig = userConfig != { };

            # Remove home-manager attrs from system config
            systemConfig = filterAttrs (name: _: !(elem name hmUserAttrs)) rawConfig;

            # systemModule can be attrset or function (cfg -> attrset)
            # Supports platform sections: allSystems, nixosSystems, darwinSystems
            resolvedSystemModuleRaw = if isFunction systemModule then systemModule cfg else systemModule;
            resolvedSystemModule =
              if isLinux then (resolvedSystemModuleRaw.nixosSystems or { }) // (resolvedSystemModuleRaw.allSystems or { })
              else if isDarwin then (resolvedSystemModuleRaw.darwinSystems or { }) // (resolvedSystemModuleRaw.allSystems or { })
              else resolvedSystemModuleRaw;
          in
          mkMerge [
            resolvedSystemModule
            (systemConfig // (optionalAttrs hasUserConfig {
              home-manager.users = mapAttrs (name: _: userConfig) enabledUsers;
            }))
            (optionalAttrs (dotfiles != null && self != null) {
              home-manager.users = mkDotfilesSymlink {
                inherit config self;
                inherit (dotfiles) path source;
                target = dotfiles.target or null;
              };
            })
          ]
        );
    };

  # System module wrapper for systems/all, systems/darwin, systems/linux modules
  # Unlike mkModuleV2, this:
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
      inherit (args) lib;

      isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
      isLinux = system == "aarch64-linux" || system == "x86_64-linux";

      # Determine if this module should be active on this platform
      platformActive =
        if namespace == "all" then true
        else if namespace == "darwin" then isDarwin
        else if namespace == "linux" then isLinux
        else false;

      # Build option path from _modulePath
      # e.g., "systemAll.nix-settings" or "systemDarwin.homebrew"
      # _modulePath comes in as e.g., "systems.all.nix-settings"
      # We transform "systems.all" -> "systemAll", "systems.darwin" -> "systemDarwin", etc.
      transformedPath =
        let
          parts = splitString "." _modulePath;
          # Check if path starts with "systems"
          startsWithSystems = (head parts) == "systems";
          # Get platform part (all/darwin/linux) and rest of path
          platformPart = if startsWithSystems then elemAt parts 1 else null;
          restParts = if startsWithSystems then drop 2 parts else tail parts;
          # Transform systems.all -> systemAll, systems.darwin -> systemDarwin, systems.linux -> systemLinux
          newFirstPart =
            if startsWithSystems then
              if platformPart == "all" then "systemAll"
              else if platformPart == "darwin" then "systemDarwin"
              else if platformPart == "linux" then "systemLinux"
              else "system${platformPart}"
            else head parts;
        in
        concatStringsSep "." ([ newFirstPart ] ++ restParts);

      pathParts = splitString "." transformedPath;

      # Get module config
      cfg = foldl' (acc: part: acc.${part} or { }) config pathParts;

      # Get enabled users for modules that need home-manager access
      enabledUsers = filterAttrs (_: u: u.enable) (config.hostUsers or { });
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

      config = mkIf (platformActive && (cfg.enable or false)) (
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
