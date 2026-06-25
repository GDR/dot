# Nix settings - cross-platform system module
{ lib, overlays, system, ... }@args:

lib.my.mkSystemModuleV2 args {
  namespace = "all";
  description = "Common Nix settings (flakes, nix-command)";

  module = _: {
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Nixpkgs configuration
    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.nvidia.acceptLicense = true;
    # bitwarden-desktop (2026.x) still depends on electron_39, which nixpkgs
    # marks as EOL/insecure. Allow it explicitly until nixpkgs bumps the
    # bitwarden-desktop recipe to a newer electron version.
    nixpkgs.config.permittedInsecurePackages = [ "electron-39.8.10" ];
    nixpkgs.overlays = [
      overlays.${system}.additions
      overlays.${system}.patches
      overlays.${system}.antigravity
      overlays.${system}.ollama
      overlays.${system}.code-cursor
      overlays.${system}.proton-ge-bin
      overlays.${system}.openldap
    ];
  };

  # Platform-specific additions
  moduleLinux = _: {
    system.stateVersion = "26.05";
  };

  moduleDarwin = _: {
    system.stateVersion = 5;
  };
}
