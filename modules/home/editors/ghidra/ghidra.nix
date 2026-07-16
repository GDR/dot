# Ghidra + GhidraMCP bridge
# ghidra: NSA reverse engineering suite (12.1.2 in nixpkgs)
# ghidra-mcp: MCP bridge that exposes 256 Ghidra tools to AI clients via HTTP
#
# Topology:
#   nix-oldstar — Ghidra runs (GUI or headless), bridge listens on :8089
#   nix-goldstar — bridge binary in PATH for Antigravity MCP config
#
# To start Ghidra headlessly (managed manually or via systemd unit):
#   ghidra --headless <project-dir> <project-name> -import <binary>
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  description = "Ghidra reverse-engineering suite + GhidraMCP bridge";
  platforms = [ "linux" ];

  module = {
    nixosSystems.home.packages = [
      pkgs.ghidra     # Ghidra 12.1.2 — required by GhidraMCP extension
      pkgs.ghidra-mcp # MCP bridge (bridge-mcp-ghidra binary)
      pkgs.maven      # needed to build/update GhidraMCP extension from source
    ];
  };
}
