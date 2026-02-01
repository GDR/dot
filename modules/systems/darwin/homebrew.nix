# Homebrew integration - Darwin-only system module
# Enables nix-homebrew for managing Homebrew via Nix
{ lib, inputs, ... }@args:

lib.my.mkSystemModuleV2 args {
  namespace = "darwin";
  description = "Homebrew package manager via nix-homebrew";

  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  extraOptions = {
    user = lib.mkOption {
      type = lib.types.str;
      description = "User account for Homebrew installation";
    };
  };

  module = cfg: {
    # Enable Homebrew
    homebrew.enable = true;

    # Enable nix-homebrew
    nix-homebrew = {
      enable = true;
      user = cfg.user;
    };
  };
}

