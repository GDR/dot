# VS Code Server - enables remote VS Code connections
# Allows connecting to this machine via VS Code Remote SSH
{ lib, ... }@args:

lib.my.mkSystemModuleV2 args {
  namespace = "linux";
  description = "VS Code Server for remote development";

  module = _: {
    # Enable the VS Code server service
    services.vscode-server.enable = true;

    # Required for VS Code server to work properly
    programs.nix-ld.enable = true;
  };
}
