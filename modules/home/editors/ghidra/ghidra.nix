# Ghidra + GhidraMCP bridge
{ lib, ... }:

lib.my.mkFeature {
  description = "Ghidra reverse-engineering suite + GhidraMCP bridge";
  platforms = [ "linux" ];

  homeModuleLinux = { pkgs, lib, ... }:
    let
      ghidraConfigDir = ".config/ghidra/ghidra_12.1.2_NIX";
      ghidraPkg = if pkgs ? ghidra-aeon then pkgs.ghidra.withExtensions (exts: [ pkgs.ghidra-aeon ]) else pkgs.ghidra;
    in
    {
      home.packages = [
        ghidraPkg
      ] ++ lib.optional (pkgs ? ghidra-mcp) pkgs.ghidra-mcp
      ++ lib.optional (pkgs ? maven) pkgs.maven;

      home.file."${ghidraConfigDir}/Extensions/GhidraMCP" = lib.mkIf (pkgs ? ghidra-mcp-extension) {
        source = pkgs.ghidra-mcp-extension;
        recursive = true;
      };
    };
}
