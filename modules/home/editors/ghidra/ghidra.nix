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
{ lib, pkgs, config, ... }@args:

let
  # Ghidra writes its config under a version+variant-specific subdirectory.
  # NixOS uses the "_NIX" variant suffix.
  ghidraConfigDir = ".config/ghidra/ghidra_12.1.2_NIX";
  ghidraPkg = if pkgs ? ghidra-aeon then pkgs.ghidra.withExtensions (exts: [ pkgs.ghidra-aeon ]) else pkgs.ghidra;
in
lib.my.mkModuleV2 args {
  description = "Ghidra reverse-engineering suite + GhidraMCP bridge";
  platforms = [ "linux" ];

  module = {
    nixosSystems.home = {
      packages = [
        ghidraPkg # Ghidra 12.1.2 (with AEON R2 if available)
        # ghidra-mcp is a custom overlay package (Linux-only); guard against cross-system
        # evaluation where the overlay may not be applied (e.g., Darwin flake check).
      ] ++ lib.optional (pkgs ? ghidra-mcp) pkgs.ghidra-mcp
      ++ lib.optional (pkgs ? maven) pkgs.maven;

      # Deploy Java extension into Ghidra's user Extensions directory.
      # Ghidra scans this dir on startup and loads GhidraMCP automatically.
      file."${ghidraConfigDir}/Extensions/GhidraMCP" = lib.mkIf (pkgs ? ghidra-mcp-extension) {
        source = pkgs.ghidra-mcp-extension;
        recursive = true;
      };
    };
  };
}
