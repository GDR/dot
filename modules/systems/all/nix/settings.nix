# Nix settings - cross-platform system module
{ lib, overlays, system, ... }@args:

lib.my.mkSystemModuleV2 args {
  namespace = "all";
  description = "Common Nix settings (flakes, nix-command)";

  module = _: {
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Nixpkgs configuration
    nixpkgs.config.allowUnfree = true;
    nixpkgs.overlays = [
      overlays.${system}.additions
      overlays.${system}.modifications
    ];
  };

  # Platform-specific additions
  moduleLinux = _: {
    system.stateVersion = "25.11";
  };

  moduleDarwin = _: {
    system.stateVersion = 5;
  };
}
