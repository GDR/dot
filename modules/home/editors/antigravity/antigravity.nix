# Antigravity IDE (1.x) - AI-powered code editor built on VS Code
# Tracks latest 1.x via the upstream antigravity-nix flake (auto-updates 3x/week).
#
# On NixOS without a keyring daemon (typical on bare Hyprland), Electron's default
# credential backend silently fails — auth tokens are never saved, so every launch
# looks like a fresh install: no login, no conversation history.
# --password-store=basic tells Electron to store credentials as plain text inside
# the app's --user-data-dir (~/.antigravity-ide), which persists normally.
{ lib, pkgs, ... }@args:

let
  # Wrap the Linux binary to force plain-text credential storage.
  # This is a thin symlinkJoin wrapper — no extra downloads.
  ideLinux = pkgs.symlinkJoin {
    name = "google-antigravity-ide-with-basic-store";
    paths = [ pkgs.google-antigravity-ide ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/antigravity-ide \
        --add-flags "--password-store=basic"
    '';
  };

  # On macOS the package ships only an .app bundle (no bin/ wrapper).
  # Build a tiny shell wrapper so 'antigravity-ide' lands on $PATH.
  antigravityIdeWrapper = pkgs.writeShellScriptBin "antigravity-ide" ''
    exec "${pkgs.google-antigravity-ide}/Applications/Antigravity IDE.app/Contents/MacOS/Antigravity IDE" "$@"
  '';
in
lib.my.mkModuleV2 args {
  description = "Antigravity IDE - VS Code-based AI editor (1.x legacy branch)";
  module = {
    nixosSystems.home.packages = [
      ideLinux
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
