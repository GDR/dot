# Nix settings - cross-platform system module
{ config, lib, overlays, system, ... }: with lib;
let
  cfg = config.systemAll.nix-settings;
in
{
  options.systemAll.nix-settings = {
    enable = mkEnableOption "common Nix settings (flakes, nix-command)";
  };

  config = mkIf cfg.enable {
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Nixpkgs configuration
    nixpkgs.config.allowUnfree = true;
    nixpkgs.overlays = [
      overlays.${system}.additions
      overlays.${system}.modifications
    ];

    system.stateVersion = "25.11";
  };
}
