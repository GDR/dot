# Core user module - defines hostUsers options
# This is a foundational module, not a typical package module
{ config, lib, system, modulesRegistry ? null, ... }:

with lib;

let
  # Platform detection - use system from specialArgs (avoids pkgs->config recursion)
  isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
  isLinux = system == "aarch64-linux" || system == "x86_64-linux";

  # Get enabled users
  enabledUsers = filterAttrs (name: cfg: cfg.enable) config.hostUsers;

  # Build module options structure from registry
  # Creates options like hostUsers.<name>.modules.<module_path>.enable
  # Uses attrs to allow nested paths like home.media.vlc.enable = true
  buildModuleOptions = registry:
    # Use attrs to allow any nested structure
    # We'll check for .enable in shouldEnableModule by traversing the path
    types.attrs;

  # SSH key submodule
  keyModule = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Key identifier, e.g. 'goldstar'";
      };
      type = mkOption {
        type = types.enum [ "rsa" "ed25519" "ecdsa" ];
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

      # Linux-specific
      extraGroups = mkOption {
        type = types.listOf types.str;
        default = [ "wheel" ];
        description = "Extra groups for the user (Linux only)";
      };

      # Per-user module configuration (hierarchical enables)
      # Enable at any level: home.browsers.enable (all browsers) or home.browsers.vivaldi.enable (specific)
      modules = mkOption {
        type = buildModuleOptions modulesRegistry;
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
    };
  });

in
{
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
  config = mkIf (enabledUsers != { }) ({
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
            uid = uidMap.${name};
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
      trusted-users = [ "root" ] ++ (attrNames enabledUsers);
      allowed-users = [ "root" ] ++ (attrNames enabledUsers);
    };

    # Configure home-manager for each enabled user
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      # Back up existing files instead of failing
      backupFileExtension = "backup";

      users = mapAttrs
        (name: cfg: {
          home = {
            stateVersion = "24.11";
            username = name;
            homeDirectory = if isDarwin then "/Users/${name}" else "/home/${name}";
          };
          # Programs and packages will be configured by modules via per-user tags (Deliverable 5)
        })
        enabledUsers;
    };
  } // optionalAttrs isDarwin {
    # Darwin requires primaryUser for certain options
    system.primaryUser = head (attrNames enabledUsers);
  });
}
