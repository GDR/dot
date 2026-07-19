# Ghidra MCP Bridge — exposes Ghidra reverse-engineering API to MCP clients.
# Runtime: python bridge talks to a running Ghidra instance (GUI or headless)
# over HTTP (default port 8089). One dep: mcp SDK >=1.28.1.
#
# Pinned to main HEAD (2026-07-16) — the v5.14.x tags predate pyproject.toml
# introduction; main has the hatchling-based build with proper pyproject.toml.
# Version string tracks upstream pyproject.toml at that commit.
{ lib
, python3Packages
, fetchFromGitHub
, python-mcp
, # local override at 1.28.1 (nixpkgs has 1.27.0)
}:

python3Packages.buildPythonApplication {
  pname = "ghidra-mcp-bridge";
  version = "5.15.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "bethington";
    repo = "ghidra-mcp";
    # Tags v5.14.x predate pyproject.toml; pin to main HEAD
    rev = "60660e20af60f458b7eeec9819c8fc78de815a56";
    hash = "sha256-8vPOs/ePOsnwO3tXKMdcL1+YmHuJX+FqFfy1ErCH39A=";
  };

  build-system = [ python3Packages.hatchling ];

  # Use our local mcp override instead of nixpkgs's older 1.27.0
  dependencies = [ python-mcp ];

  # hatch.build.targets.wheel.packages = ["python/bridge_mcp_ghidra"]
  # defined in pyproject.toml — hatchling handles the python/ subdir automatically

  doCheck = false;
  pythonImportsCheck = [ "bridge_mcp_ghidra" ];

  meta = {
    description = "GhidraMCP bridge — MCP server exposing 256 Ghidra reverse-engineering tools";
    homepage = "https://github.com/bethington/ghidra-mcp";
    changelog = "https://github.com/bethington/ghidra-mcp/blob/main/CHANGELOG.md";
    license = lib.licenses.asl20;
    mainProgram = "bridge-mcp-ghidra";
    platforms = lib.platforms.linux;
  };
}
