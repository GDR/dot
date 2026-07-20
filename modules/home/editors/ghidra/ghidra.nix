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
      pkgs.ghidra # Ghidra 12.1.2 — required by GhidraMCP extension
      # ghidra-mcp is a custom overlay package (Linux-only); guard against cross-system
      # evaluation where the overlay may not be applied (e.g., Darwin flake check).
    ] ++ lib.optional (pkgs ? ghidra-mcp) pkgs.ghidra-mcp
    ++ lib.optional (pkgs ? maven) pkgs.maven;
  };
}
