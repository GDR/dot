# Core user module - defines hostUsers options
# This is a foundational module, not a typical package module
{ config, lib, pkgs, ... }:

with lib;

let
  # Platform detection
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # Get enabled users
  enabledUsers = filterAttrs (name: cfg: cfg.enable) config.hostUsers;

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
        default = [];
        description = "SSH keys for this user";
      };

      # Linux-specific
      extraGroups = mkOption {
        type = types.listOf types.str;
        default = [ "wheel" ];
        description = "Extra groups for the user (Linux only)";
      };

      # Per-user tags for enabling user-scope modules
      tags = {
        enable = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Enable user modules with these tags";
          example = [ "core" "media" "editors" ];
        };
        explicit = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Explicitly enable these user modules by path";
          example = [ "editors.neovim" "media.vlc" ];
        };
      };

      # Per-user explicit module configuration (for future use)
      modules = mkOption {
        type = types.attrs;
        default = {};
        description = "Explicit module configuration for this user";
      };
    };
  });

in
{
  options.hostUsers = mkOption {
    type = types.attrsOf userModule;
    default = {};
    description = ''
      Users to configure on this host.
      Each user can have their own set of modules enabled via tags.
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
          tags.enable = [ "core" "media" ];
        };
      }
    '';
  };

  # Create system users from enabled hostUsers
  config = mkIf (enabledUsers != {}) {
    # Create users.users entries for each enabled hostUser
    users.users = mapAttrs (name: cfg: {
      name = name;
      isNormalUser = true;
      home = if isDarwin then "/Users/${name}" else "/home/${name}";
      group = if isLinux then "users" else "staff";
      uid = 1000;  # TODO: support multiple users with different UIDs
      extraGroups = mkIf isLinux cfg.extraGroups;
    }) enabledUsers;

    # Add users to nix trusted/allowed users
    nix.settings = {
      trusted-users = [ "root" ] ++ (attrNames enabledUsers);
      allowed-users = [ "root" ] ++ (attrNames enabledUsers);
    };

    # Configure home-manager for each enabled user
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;

      users = mapAttrs (name: cfg: {
        home = {
          stateVersion = "24.11";
          username = name;
          homeDirectory = if isDarwin then "/Users/${name}" else "/home/${name}";
        };
        # Programs and packages will be configured by modules via per-user tags (Deliverable 5)
      }) enabledUsers;
    };
  };
}
