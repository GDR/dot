# Core user module - defines hostUsers options
# This is a foundational module, not a typical package module
{ config, lib, pkgs, ... }:

with lib;

let
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
        type = types.enum [ "git" "ssh" "both" ];
        default = "both";
        description = "What this key is used for";
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
            purpose = "both";
            isDefault = true;
          }];
          tags.enable = [ "core" "media" ];
        };
      }
    '';
  };

  # Config will be added in Deliverable 3
  # For now, just defining options
  config = {
    # Placeholder - no effect yet
  };
}
