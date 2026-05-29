# Antigravity IDE (1.x) - AI-powered code editor built on VS Code
# Tracks latest 1.x via the upstream antigravity-nix flake (auto-updates 3x/week).
{ lib, pkgs, ... }@args:

let
  # On macOS the package ships only an .app bundle (no bin/ wrapper).
  # Build a tiny shell wrapper so 'antigravity-ide' lands on $PATH.
  antigravityIdeWrapper = pkgs.writeShellScriptBin "antigravity-ide" ''
    exec "${pkgs.google-antigravity-ide}/Applications/Antigravity IDE.app/Contents/MacOS/Antigravity IDE" "$@"
  '';
in
lib.my.mkModuleV2 args {
  description = "Antigravity IDE - VS Code-based AI editor (1.x legacy branch)";
  module = {
    # Linux: google-antigravity-ide ships a proper bin/antigravity-ide
    nixosSystems.home.packages = [
      pkgs.google-antigravity-ide
      pkgs.google-antigravity-cli
    ];

    # macOS: .app bundle only — use the wrapper script instead
    darwinSystems.home.packages = [
      antigravityIdeWrapper
      pkgs.google-antigravity-ide # still needed for the .app in ~/Applications
      pkgs.google-antigravity-cli
    ];
  };
}
