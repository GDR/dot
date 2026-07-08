# VS Code Server - enables remote VS Code connections
# Allows connecting to this machine via VS Code Remote SSH and Antigravity IDE
{ lib, ... }@args:

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
    };

    # Required for VS Code server / Antigravity IDE server to work properly
    programs.nix-ld.enable = true;
  };
}
