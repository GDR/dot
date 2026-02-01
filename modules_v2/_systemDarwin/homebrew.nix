# Homebrew integration - Darwin-only system module
# Enables nix-homebrew for managing Homebrew via Nix
{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.systemDarwin.homebrew;
in
{
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  options.systemDarwin.homebrew = {
    enable = lib.mkEnableOption "Homebrew package manager via nix-homebrew";

    user = lib.mkOption {
      type = lib.types.str;
      description = "User account for Homebrew installation";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable Homebrew
    homebrew.enable = true;

    # Enable nix-homebrew
    nix-homebrew = {
      enable = true;
      user = cfg.user;
    };
  };
}

