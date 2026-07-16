# GhidraMCP Java extension — the Ghidra plugin that starts the HTTP server on :8089.
# Built from source (Maven) with Ghidra 12.1.2 JARs, then committed as a binary artifact.
# The bridge (pkgs.ghidra-mcp) talks to this HTTP endpoint.
#
# Rebuild steps (when updating ghidra-mcp upstream):
#   cd /tmp && git clone https://github.com/bethington/ghidra-mcp.git && cd ghidra-mcp
#   GHIDRA=/nix/store/.../lib/ghidra  # path to current pkgs.ghidra
#   nix-shell -p python3 maven uv jdk21 --run "python3 -m tools.setup ensure-prereqs --ghidra-path $GHIDRA"
#   nix-shell -p maven jdk21 --run "python3 -m tools.setup build"
#   cp target/GhidraMCP-*.zip <dot>/pkgs/ghidra-mcp-extension/
#   # update version + hash below
{ lib, stdenvNoCC, unzip }:

stdenvNoCC.mkDerivation {
  pname = "ghidra-mcp-extension";
  version = "5.15.0";

  src = ./GhidraMCP-5.15.0.zip;

  nativeBuildInputs = [ unzip ];

  # unpackPhase handled by stdenv zip support
  dontBuild = true;

  installPhase = ''
    # unpackPhase sets sourceRoot=GhidraMCP and cd's into it,
    # so '.' already contains lib/, extension.properties, Module.manifest
    mkdir -p $out
    cp -r . $out/
  '';

  meta = {
    description = "GhidraMCP Java extension — HTTP MCP server plugin for Ghidra 12.1.2";
    homepage = "https://github.com/bethington/ghidra-mcp";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
