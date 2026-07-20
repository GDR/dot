# VS Code Server — remote development daemon for VS Code / Cursor / Antigravity IDE
#
# This is a HOME module: enable per-user like any other editor.
# When any enabled user has it, the system daemon activates automatically (via systemModule).
#
# The daemon patches ~/.vscode-server (and sibling dirs) so that the remote server
# binaries VS Code drops there survive NixOS's non-FHS filesystem layout.
# Also enables nix-ld so dynamically-linked server extensions work without friction.
#
# Enable: hostUsers.<user>.modules.home.editors.vscode-server.enable = true
# Or via the developer/server profile.
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "linux" ];
  description = "VS Code Server / Antigravity IDE remote development daemon";

  # System-level: the daemon and nix-ld are machine-wide concerns.
  # Activates when ANY enabled user has this module enabled.
  systemModule = {
    nixosSystems = {
      services.vscode-server = {
        enable = true;

        # Watch all remote-server install paths:
        #   ~/.vscode-server          – VS Code / Cursor
        #   ~/.antigravity-ide-server – Antigravity IDE (current)
        #   ~/.antigravity-server     – Antigravity IDE (legacy)
        installPath = [
          "$HOME/.vscode-server"
          "$HOME/.antigravity-ide-server"
          "$HOME/.antigravity-server"
        ];

        # The Antigravity server startup script calls /usr/bin/pgrep (hardcoded).
        extraRuntimeDependencies = [ pkgs.procps ];
      };

      # Required for VS Code server extensions to work on NixOS (no FHS).
      programs.nix-ld.enable = true;

      # pgrep must be on PATH for all sessions (/usr/bin is read-only on NixOS).
      environment.systemPackages = [ pkgs.procps ];
    };
  };

  # No home-manager config needed — the daemon does everything at the system level.
  module = { };
}
