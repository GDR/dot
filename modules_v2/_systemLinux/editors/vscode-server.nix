# VS Code Server - enables remote VS Code connections
# Allows connecting to this machine via VS Code Remote SSH
{ config, lib, ... }: with lib;
let
  cfg = config.systemLinux.editors.vscode-server;
in
{
  options.systemLinux.editors.vscode-server = {
    enable = mkEnableOption "VS Code Server for remote development";
  };

  config = mkIf cfg.enable {
    # Enable the VS Code server service
    services.vscode-server.enable = true;

    # Required for VS Code server to work properly
    programs.nix-ld.enable = true;
  };
}
