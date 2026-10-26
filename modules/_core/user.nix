# Core user module - defines hostUsers options
# This is a foundational module, not a typical package module
{ config, lib, system, pkgs, modulesRegistry ? null, self ? null, inputs ? { }, ... }@args:

with lib;

let
  # Platform detection - use system from specialArgs (avoids pkgs->config recursion)
  isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
  isLinux = system == "aarch64-linux" || system == "x86_64-linux";

  # Get enabled users
  enabledUsers = filterAttrs (name: cfg: cfg.enable) config.hostUsers;

  # Feature catalog and option generation
  featureCatalog =
    if modulesRegistry != null then (modulesRegistry.features or modulesRegistry.featureCatalog or [ ])
    else [ ];
  allKnownModulePaths =
    if modulesRegistry != null then map (m: m.path) (modulesRegistry.allModules or modulesRegistry.modules or [ ])
    else [ ];

  userFeatureOptions = lib.my.buildFeatureOptionTree {
    inherit featureCatalog;
    knownModulePaths = allKnownModulePaths;
    scope = "user";
  };

  systemFeatureOptions = lib.my.buildFeatureOptionTree {
    inherit featureCatalog;
    knownModulePaths = allKnownModulePaths;
    scope = "system";
  };

  # SSH key submodule
  keyModule = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Key identifier, e.g. 'goldstar'";
      };
      type = mkOption {
        type = types.enum [ "rsa" "ed25519" "ecdsa" "ecdsa-sk" ];
        default = "rsa";
        description = "SSH key type";
      };
      purpose = mkOption {
        type = types.listOf (types.enum [ "git" "ssh" ]);
        default = [ "git" "ssh" ];
        description = "What this key is used for";
        example = [ "git" "ssh" ];
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
  userModule = types.submodule ({ name, ... }: {
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
        type = types.listOf (types.submodule ({ config, ... }: {
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
            extraConfig = mkOption {
              type = types.attrsOf types.str;
              default = { };
              description = "Additional SSH options (e.g., AddKeysToAgent, Compression)";
            };
            extraOptions = mkOption {
              type = types.attrsOf types.str;
              default = { };
              description = "Deprecated alias for extraConfig";
            };
          };
          config = {
            extraConfig = mkIf (config.extraOptions != { }) config.extraOptions;
          };
        }));
        default = [ ];
        description = "SSH host configurations";
      };

      # SSH config includes
      sshIncludes = mkOption {
        type = types.listOf types.str;
        default = [ "~/.ssh/config.d/*" ];
        description = "Additional SSH config files to include";
      };

      # Clavis SSH Agent integration
      clavisAgent = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Clavis SSH Agent integration for this user";
        };
        socketPath = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Custom Clavis SSH Agent socket path. If null, uses ~/.ssh/clavis.sock";
        };
      };

      # Bitwarden SSH Agent integration
      bitwardenSshAgent = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Bitwarden SSH Agent integration for this user";
        };
        socketPath = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Custom Bitwarden SSH Agent socket path. If null, uses platform default.";
        };
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
        default = [ ];
        description = "Extra groups for the user (Linux only)";
      };

      trustedNixUser = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to add this user to nix.settings.trusted-users";
      };

      # Per-user module configuration (hierarchical enables)
      # Enable at any level: home.browsers.enable (all browsers) or home.browsers.vivaldi.enable (specific)
      modules = mkOption {
        type = types.submodule {
          options = userFeatureOptions;
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
  });

in
{
  options.modules = systemFeatureOptions;

  options._modulesRegistry = mkOption {
    internal = true;
    default = modulesRegistry;
    description = "Internal reference to modulesRegistry";
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

  # Create system users from enabled hostUsers and compile features
  config = mkMerge [
    (mkIf (enabledUsers != { }) ({
      # Create users.users entries for each enabled hostUser
      # Note: Darwin users are managed differently - only set Linux-specific options on Linux
      users.users =
        let
          # Generate UIDs starting from 1000, incrementing for each user
          # This ensures unique UIDs for multiple users
          userNames = attrNames enabledUsers;
          # Helper to create UID mapping: first user gets 1000, second gets 1001, etc.
          createUidMap = names: idx:
            if names == [ ] then { }
            else
              (createUidMap (tail names) (idx + 1)) // {
                ${head names} = 1000 + idx;
              };
          uidMap = createUidMap userNames 0;
        in
        mapAttrs
          (name: cfg:
            if isLinux then {
              name = name;
              isNormalUser = true;
              home = "/home/${name}";
              group = "users";
              uid = if cfg.uid != null then cfg.uid else uidMap.${name};
              extraGroups = cfg.extraGroups;
            } else {
              # Darwin: minimal user config, home-manager handles the rest
              name = name;
              home = "/Users/${name}";
            }
          )
          enabledUsers;

      # Add users to nix trusted/allowed users
      nix.settings = {
        trusted-users = [ "root" ] ++ (attrNames (filterAttrs (_: u: u.trustedNixUser) enabledUsers));
        allowed-users = [ "root" ] ++ (attrNames enabledUsers);
      };

      # Configure home-manager for each enabled user
      home-manager = {
        useUserPackages = true;
        useGlobalPkgs = true;
        # Back up existing files instead of failing
        backupFileExtension = "backup";

        users = mapAttrs
          (userName: userCfg:
            hmArgs: {
              imports = lib.my.compileUserHomeModules {
                osConfig = hmArgs.osConfig or config;
                inherit pkgs userName userCfg featureCatalog modulesRegistry;
                self = args.self or null;
                inputs = args.inputs or { };
              };
              home = {
                stateVersion = "26.05";
                username = userName;
                homeDirectory = if isDarwin then "/Users/${userName}" else "/home/${userName}";
              };
            }
          )
          enabledUsers;
      };
    } // optionalAttrs isDarwin {
      # Darwin requires primaryUser for certain options
      system.primaryUser = head (attrNames enabledUsers);
    } // optionalAttrs isLinux {
      # Grant NOPASSWD sudo to any user that opted in
      security.sudo.extraRules =
        let
          nopasswdUsers = filterAttrs (_: cfg: cfg.enable && cfg.sudo.nopasswd) config.hostUsers;
        in
        mapAttrsToList
          (name: _: {
            users = [ name ];
            commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
          })
          nopasswdUsers;
    }))

    (lib.my.compileSystemFeatureModules {
      inherit config pkgs lib system featureCatalog modulesRegistry;
    })
  ];
}
