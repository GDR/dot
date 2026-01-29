{ lib, ... }: with lib; with types; rec {
  # Import module registry functions
  moduleRegistry = import ./moduleRegistry.nix { inherit lib; };

  # Re-export module registry functions for convenience
  resolveEnabledModules = moduleRegistry.resolveEnabledModules;
  modulesByTags = moduleRegistry.modulesByTags;
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
      hmUserAttrs = [ "home" "programs" "xdg" "services" "systemd" "gtk" "qt" "dconf" "accounts" "fonts" "manual" "news" "nix" "targets" "wayland" "xresources" "xsession" ];

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

  # Module metadata structure
  mkModuleMeta =
    { requires ? [ ]
    , # List of module paths: ["common.shell.git", "common.utils.bazel"]
      platforms ? [ "linux" "darwin" ]
    , tags ? [ ]
    , # List of tags: ["media", "ui", "desktop"]
      scope ? "user"
    , # "system" = system services/drivers, "user" = home.packages
      description ? null
    }: {
      inherit requires platforms tags scope description;
    };

  # Helper to derive config accessor from module path
  # Usage:
  #   let mod = lib.my.modulePath [ "common" "browsers" "firefox" ] config;
  #   in { options.modules.common.browsers.firefox = ...; config = mkIf mod.cfg.enable ...; }
  modulePath = pathParts: config:
    let
      cfgAccessor = foldl (acc: part: acc.${part}) config.modules pathParts;
    in
    {
      cfg = cfgAccessor;
    };

  # Check if a module should be enabled based on its config, tags, and explicit enables
  # Also checks per-user tags in hostUsers.<name>.tags
  # Usage (inside config block):
  #   shouldEnable = lib.my.shouldEnableModule {
  #     inherit config;
  #     modulePath = "common.media.vlc";
  #     moduleTags = [ "media" ];
  #   };
  shouldEnableModule = { config, modulePath, moduleTags }:
    let
      pathParts = splitString "." modulePath;
      cfg = foldl (acc: part: acc.${part}) config.modules pathParts;

      # Global tags (modules.tags)
      globalTags = config.modules.tags or { enable = [ ]; explicit = [ ]; };

      # Per-user tags (hostUsers.<name>.tags)
      enabledUsers = filterAttrs (name: ucfg: ucfg.enable or false) (config.hostUsers or { });
      userTagsLists = mapAttrsToList (name: ucfg: ucfg.tags or { enable = [ ]; explicit = [ ]; }) enabledUsers;

      # Check if any user has this module's tag enabled
      anyUserHasTag = any (userTags: any (tag: elem tag (userTags.enable or [ ])) moduleTags) userTagsLists;
      anyUserHasExplicit = any (userTags: elem modulePath (userTags.explicit or [ ])) userTagsLists;
    in
    cfg.enable
    || any (tag: elem tag globalTags.enable) moduleTags
    || elem modulePath globalTags.explicit
    || anyUserHasTag
    || anyUserHasExplicit;

  # Get list of users who have a module enabled via tags
  # Usage: usersWithModule = lib.my.getUsersWithModule { inherit config modulePath moduleTags; };
  getUsersWithModule = { config, modulePath, moduleTags }:
    let
      enabledUsers = filterAttrs (name: ucfg: ucfg.enable or false) (config.hostUsers or { });
    in
    filterAttrs
      (name: ucfg:
        let
          userTags = ucfg.tags or { enable = [ ]; explicit = [ ]; };
        in
        any (tag: elem tag (userTags.enable or [ ])) moduleTags
        || elem modulePath (userTags.explicit or [ ])
      )
      enabledUsers;

  # Create XDG config symlink to repo dotfiles for all enabled users
  # This allows editing config files without rebuild
  # Usage:
  #   config.home-manager.users = lib.my.mkDotfilesSymlink {
  #     inherit config self;
  #     path = "ghostty";                                    # ~/.config/ghostty
  #     source = "modules_v2/common/terminal/ghostty/dotfiles";  # relative path in repo
  #   };
  mkDotfilesSymlink = { config, self, path, source }:
    let
      enabledUsers = filterAttrs (_: u: u.enable) (config.hostUsers or { });
      # Use self.outPath to get actual repo path (not nix store)
      repoPath = self.outPath;
      fullPath = "${repoPath}/${source}";
    in
    mapAttrs
      (name: _: {
        xdg.configFile.${path}.source =
          config.home-manager.users.${name}.lib.file.mkOutOfStoreSymlink fullPath;
      })
      enabledUsers;

  # Generate module options from path string
  # Usage:
  #   options = lib.my.mkModuleOptions "common.core.htop" {
  #     enable = mkOption { default = false; type = types.bool; };
  #   };
  # Returns: { modules.common.core.htop = { enable = ...; }; }
  mkModuleOptions = modulePath: opts:
    let
      pathParts = splitString "." modulePath;
    in
    { modules = setAttrByPath pathParts opts; };

  # Complete module wrapper for modules_v2
  # Usage:
  #   lib.my.mkModuleV2 {
  #     inherit config pkgs system _modulePath;
  #     tags = [ "core" ];
  #     description = "htop - interactive process viewer";
  #     module = {
  #       allSystems.home.packages = with pkgs; [ htop ];
  #     };
  #   }
  # Module sections: allSystems, nixosSystems, darwinSystems
  # home.* config is automatically routed to all enabled hostUsers
  mkModuleV2 =
    { config
    , pkgs
    , system
    , _modulePath
    , tags
    , requires ? [ ]
    , platforms ? [ "linux" "darwin" ]
    , description ? null
    , module
    }:
    let
      modulePath = _modulePath;
      moduleTags = tags;

      isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
      isLinux = system == "aarch64-linux" || system == "x86_64-linux";

      rawConfig =
        if isLinux then (module.nixosSystems or { }) // (module.allSystems or { })
        else if isDarwin then (module.darwinSystems or { }) // (module.allSystems or { })
        else { };

      # Home-manager user-level attributes (routed to home-manager.users.*)
      hmUserAttrs = [ "home" "programs" "xdg" "services" "systemd" "gtk" "qt" "dconf" "accounts" "fonts" "manual" "news" "nix" "targets" "wayland" "xresources" "xsession" ];

      # Extract home-manager attrs from config
      userConfig = filterAttrs (name: _: elem name hmUserAttrs) rawConfig;
      hasUserConfig = userConfig != { };

      # Remove home-manager attrs from system config
      systemConfig = filterAttrs (name: _: !(elem name hmUserAttrs)) rawConfig;

      # Get enabled users for home config routing
      enabledUsers = filterAttrs (_: u: u.enable) (config.hostUsers or { });
    in
    {
      meta = mkModuleMeta {
        inherit requires platforms tags description;
      };

      options = mkModuleOptions modulePath {
        enable = mkOption {
          default = false;
          type = bool;
        };
      };

      config =
        let
          shouldEnable = shouldEnableModule { inherit config modulePath moduleTags; };
        in
        mkIf shouldEnable (
          systemConfig // (optionalAttrs hasUserConfig {
            home-manager.users = mapAttrs (name: _: userConfig) enabledUsers;
          })
        );
    };
}
