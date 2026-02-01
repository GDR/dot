# Nix settings - cross-platform system module
{ config, lib, overlays, system, ... }: with lib;
let
  cfg = config.systemAll.nix-settings;
  isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
  isLinux = system == "aarch64-linux" || system == "x86_64-linux";
in
{
  options.systemAll.nix-settings = {
    enable = mkEnableOption "common Nix settings (flakes, nix-command)";
  };

  config = mkIf cfg.enable ({
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Nixpkgs configuration
    nixpkgs.config.allowUnfree = true;
    nixpkgs.overlays = [
      overlays.${system}.additions
      overlays.${system}.modifications
    ];
  } // optionalAttrs isLinux {
    # NixOS uses string stateVersion
    system.stateVersion = "25.11";
  } // optionalAttrs isDarwin {
    # Darwin uses integer stateVersion (1-6)
    system.stateVersion = 5;
  });
}
