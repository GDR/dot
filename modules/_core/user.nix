# Core user module - defines hostUsers options
# This is a foundational module, not a typical package module
{
  config,
  options,
  lib,
  system,
  pkgs,
  modulesRegistry ? null,
  self ? null,
  inputs ? { },
  ...
}@args:

with lib;

let
  # Platform detection - use system from specialArgs (avoids pkgs->config recursion)
  isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
  isLinux = system == "aarch64-linux" || system == "x86_64-linux";

  # Get enabled users
  enabledUsers = filterAttrs (name: cfg: cfg.enable) config.hostUsers;

  # Feature catalog and option generation
  featureCatalog =
    if modulesRegistry != null then
      (modulesRegistry.features or modulesRegistry.featureCatalog or [ ])
    else
      [ ];
  allKnownModulePaths =
    if modulesRegistry != null then
      map (m: m.path) (modulesRegistry.allModules or modulesRegistry.modules or [ ])
    else
      [ ];

  generatedFeatureOptions = lib.my.buildFeatureOptionTree {
    inherit featureCatalog;
    knownModulePaths = allKnownModulePaths;
  };

  # Forward explicitly set option values from host-level `modules`
  # into `hostUsers.<user>.modules`. Options with defaults have isDefined = true at
  # priority 1500 (`mkOptionDefault`); gating on `highestPrio < 1500` avoids promoting
  # unset defaults so per-user `lib.mkDefault` (priority 1000) never collides.
  forwardTree =
    optTree: schemaTree:
    concatMapAttrs (
      k: v:
      if isOption v then
        if k == "enable" then
          { }
        else
          let
            gOpt = optTree.${k};
            explicitlySet = gOpt.isDefined && gOpt.highestPrio < 1500;
          in
          {
            ${k} = mkIf explicitlySet (mkOverride 1100 gOpt.value);
          }
      else
        { ${k} = forwardTree optTree.${k} v; }
    ) schemaTree;

  # SSH key submodule
  keyModule = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Key identifier, e.g. 'goldstar'";
      };
      type = mkOption {
        type = types.enum [
          "rsa"
          "ed25519"
          "ecdsa"
          "ecdsa-sk"
        ];
        default = "rsa";
        description = "SSH key type";
      };
      purpose = mkOption {
        type = types.listOf (
          types.enum [
            "git"
            "ssh"
          ]
        );
        default = [
          "git"
          "ssh"
        ];
        description = "What this key is used for";
        example = [
          "git"
          "ssh"
        ];
      };
      isDefault = mkOption {
        type = types.bool;
        default = false;
        description = "Whether this is the default key for SSH";
      };
      publicKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Public key string (non-sensitive, safe to commit to repo)";
      };
    };
  };

  # User submodule - defines all options for a single user
  # Use submoduleWith (shorthandOnlyDefinesConfig = false) so host configs can use `imports = [ ../../users/<name>.nix ];` inside hostUsers.<name>.
  userModule = types.submoduleWith {
    modules = [
      (
        { name, ... }:
        {
          options = {
            enable = mkEnableOption "user ${name}";

            # Basic user info
            fullName = mkOption {
              type = types.str;
              default = "";
              description = "Full name for git commits";
            };

            email = mkOption {
              type = types.str;
              default = "";
              description = "Email for git commits";
            };

            github = mkOption {
              type = types.str;
              default = "";
              description = "GitHub username for SSH config";
            };

            # SSH keys
            keys = mkOption {
              type = types.listOf keyModule;
              default = [ ];
              description = "SSH keys for this user";
            };

            # SSH configuration
            ssh = mkOption {
              type = types.listOf (
                types.submodule {
                  options = {
                    host = mkOption {
                      type = types.str;
                      description = "SSH host/match pattern (e.g., '*', 'github.com', '*.example.com')";
                    };
                    user = mkOption {
                      type = types.nullOr types.str;
                      default = null;
                      description = "SSH username";
                    };
                    identityFile = mkOption {
                      type = types.nullOr (types.either types.str (types.listOf types.str));
                      default = null;
                      description = "Path to SSH identity file(s)";
                    };
                    forwardAgent = mkOption {
                      type = types.nullOr types.bool;
                      default = null;
                      description = "Enable SSH agent forwarding";
                    };
                    port = mkOption {
                      type = types.nullOr types.int;
                      default = null;
                      description = "SSH port";
                    };
                    hostname = mkOption {
                      type = types.nullOr types.str;
                      default = null;
                      description = "Actual hostname/IP address";
                    };
                    extraOptions = mkOption {
                      type = types.attrsOf types.str;
                      default = { };
                      description = "Additional SSH options (e.g., AddKeysToAgent, Compression)";
                    };
                  };
                }
              );
              default = [ ];
              description = "SSH host configurations";
            };

            # SSH config includes
            sshIncludes = mkOption {
              type = types.listOf types.str;
              default = [ "~/.ssh/config.d/*" ];
              description = "Additional SSH config files to include";
            };

            nixTrusted = mkEnableOption "granting root-equivalent nix-daemon trusted-user access";
            isPrimary = mkEnableOption "designating this user as system.primaryUser on Darwin";

            stateVersion = mkOption {
              type = types.str;
              default = "26.05";
              description = "Home Manager stateVersion for this user.";
            };

            # Linux-specific
            uid = mkOption {
              type = types.nullOr types.int;
              default = null;
              description = ''
                Fixed UID for this user (Linux only). If null, assigned by
                alphabetical order starting from 1000 — fragile if a second
                user whose name sorts earlier is added. Prefer setting this
                explicitly in hosts/users/<name>.nix.
              '';
            };

            extraGroups = mkOption {
              type = types.listOf types.str;
              default = [ "wheel" ];
              description = "Extra groups for the user (Linux only)";
            };

            # Per-user module configuration (hierarchical enables)
            # Enable at any level: home.browsers.enable (all browsers) or home.browsers.vivaldi.enable (specific)
            modules = mkOption {
              type = types.submoduleWith {
                modules = [
                  {
                    options = generatedFeatureOptions;
                    config = forwardTree options.modules generatedFeatureOptions;
                  }
                ];
              };
              default = { };
              description = ''
                Module configuration for this user.
                Enable at any path level - parent enables cascade to children.
                Example: modules.home.browsers.enable = true (enables all browsers)
              '';
              example = literalExpression ''
                {
                  home.browsers.enable = true;        # all browsers
                  home.editors.neovim.enable = true;  # specific editor
                }
              '';
            };

            # Sudo configuration (Linux only)
            sudo = {
              nopasswd = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Grant this user NOPASSWD sudo on Linux.
                  Useful for deploy-rs or other unattended automation that
                  SSHes as the user and needs to switch to root.
                '';
              };
            };
          };
        }
      )
    ];
  };

in
{
  imports = lib.my.compileSystemFeatureModules {
    inherit
      lib
      system
      featureCatalog
      modulesRegistry
      ;
  };

  options.dotfiles.live = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Global default for dotfile symlinking mode across all features.
      When true, creates live-editable out-of-store symlinks to DOTFILES_DIR;
      when false, symlinks immutable copies from the Nix store.
    '';
  };

  options.modules = generatedFeatureOptions;

  options._modulesRegistry = mkOption {
    internal = true;
    default = modulesRegistry;
    description = "Internal reference to modulesRegistry";
  };

  options._enabledFeatureSets = mkOption {
    internal = true;
    readOnly = true;
    default = genAttrs (attrNames enabledUsers) (
      u:
      lib.my.computeEnabledFeatureSetForUser {
        cfg = config;
        inherit modulesRegistry;
        userName = u;
        catalog = featureCatalog;
        hostPlatform = if isDarwin then "darwin" else "linux";
      }
    );
    description = "Internal cached per-user enabled feature sets";
  };

  options.hostUsers = mkOption {
    type = types.attrsOf userModule;
    default = { };
    description = ''
      Users to configure on this host.
      Each user can have their own set of modules enabled hierarchically.
    '';
    example = literalExpression ''
      {
        dgarifullin = {
          enable = true;
          fullName = "Damir Garifullin";
          email = "gosugdr@gmail.com";
          github = "gdr";
          keys = [{
            name = "goldstar";
            type = "rsa";
            purpose = [ "git" "ssh" ];
            isDefault = true;
          }];
          ssh = [
            {
              host = "*";
              identityFile = "~/.ssh/goldstar_id_rsa";
              extraOptions.AddKeysToAgent = "yes";
            }
            {
              host = "github.com";
              user = "git";
              identityFile = "~/.ssh/goldstar_id_rsa";
            }
          ];
          # Hierarchical module enables
          modules = {
            home.browsers.enable = true;        # enables all browsers
            home.editors.neovim.enable = true;  # specific module
          };
        };
      }
    '';
  };

  # Create system users from enabled hostUsers
  config = mkIf (enabledUsers != { }) (
    let
      userNames = attrNames enabledUsers;
      explicitUids = mapAttrsToList (_: u: u.uid) (filterAttrs (_: u: u.uid != null) enabledUsers);
      unassignedNames = attrNames (filterAttrs (_: u: u.uid == null) enabledUsers);
      nextFreeUid =
        candidate: used: if elem candidate used then nextFreeUid (candidate + 1) used else candidate;
      assignUids =
        names: used: acc:
        if names == [ ] then
          acc
        else
          let
            chosen = nextFreeUid 1000 used;
          in
          assignUids (tail names) (used ++ [ chosen ]) (acc // { ${head names} = chosen; });
      uidMap = assignUids unassignedNames explicitUids { };

      primaryUsers = attrNames (filterAttrs (_: u: u.isPrimary) enabledUsers);
      resolvedPrimaryUser = if primaryUsers != [ ] then head primaryUsers else head userNames;
    in
    {
      assertions = [
        {
          assertion = length primaryUsers <= 1;
          message = "At most one enabled hostUsers entry may set isPrimary = true (found: ${concatStringsSep ", " primaryUsers}).";
        }
        {
          assertion = !isDarwin || length userNames <= 1 || length primaryUsers == 1;
          message = "Darwin hosts with multiple enabled hostUsers must set isPrimary = true on exactly one user.";
        }
      ];

      # Create users.users entries for each enabled hostUser
      # Note: Darwin users are managed differently - only set Linux-specific options on Linux
      users.users = mapAttrs (
        name: cfg:
        if isLinux then
          {
            name = name;
            isNormalUser = true;
            home = "/home/${name}";
            group = "users";
            uid = if cfg.uid != null then cfg.uid else uidMap.${name};
            extraGroups = cfg.extraGroups;
          }
        else
          {
            # Darwin: minimal user config, home-manager handles the rest
            name = name;
            home = "/Users/${name}";
          }
      ) enabledUsers;

      # Grant nix-daemon trusted-users only to explicitly opted-in users (NixOS/Darwin already include root)
      nix.settings = {
        trusted-users = attrNames (filterAttrs (_: u: u.nixTrusted) enabledUsers);
        allowed-users = [ "root" ] ++ userNames;
      };

      # Configure home-manager for each enabled user
      home-manager = {
        useUserPackages = true;
        useGlobalPkgs = true;
        # Back up existing files instead of failing
        backupFileExtension = "backup";
        sharedModules = [
          ./detached-repos-hm.nix
        ]
        ++ optional (
          inputs ? learnharness && inputs.learnharness ? homeManagerModules.default
        ) inputs.learnharness.homeManagerModules.default
        ++ optional (
          inputs ? agentic && inputs.agentic ? homeManagerModules.default
        ) inputs.agentic.homeManagerModules.default;

        users = mapAttrs (userName: userCfg: hmArgs: {
          imports = lib.my.compileUserHomeModules {
            osConfig = hmArgs.osConfig or config;
            inherit
              pkgs
              userName
              userCfg
              featureCatalog
              modulesRegistry
              ;
            self = args.self or null;
            inputs = args.inputs or { };
          };
          home = {
            stateVersion = userCfg.stateVersion;
            username = userName;
            homeDirectory = if isDarwin then "/Users/${userName}" else "/home/${userName}";
          };
        }) enabledUsers;
      };
    }
    // optionalAttrs isDarwin {
      # Darwin requires primaryUser for certain options
      system.primaryUser = resolvedPrimaryUser;
    }
    // optionalAttrs isLinux {
      # Grant NOPASSWD sudo to any user that opted in
      security.sudo.extraRules =
        let
          nopasswdUsers = filterAttrs (_: cfg: cfg.enable && cfg.sudo.nopasswd) config.hostUsers;
        in
        mapAttrsToList (name: _: {
          users = [ name ];
          commands = [
            {
              command = "ALL";
              options = [ "NOPASSWD" ];
            }
          ];
        }) nopasswdUsers;
    }
  );
}
