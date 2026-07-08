# VS Code Server - enables remote VS Code connections
# Allows connecting to this machine via VS Code Remote SSH and Antigravity IDE
{ lib, pkgs, ... }@args:

lib.my.mkSystemModuleV2 args {
  namespace = "linux";
  description = "VS Code Server / Antigravity IDE for remote development";

  module = _: {
    # Enable the VS Code server service
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
      # Make procps available so pgrep resolves correctly on NixOS.
      extraRuntimeDependencies = [ pkgs.procps ];
    };

    # Expose pgrep at /usr/bin/pgrep for the Antigravity server startup script.
    # The script hardcodes this path and cannot be reconfigured.
    # Use tmpfiles to create the symlink — environment.etc only manages /etc.
    systemd.tmpfiles.rules = [
      "L+ /usr/bin/pgrep - - - - ${pkgs.procps}/bin/pgrep"
    ];

    # Required for VS Code server / Antigravity IDE server to work properly
    programs.nix-ld.enable = true;
  };
}
