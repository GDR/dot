# mcp Python SDK 1.28.1
# Nixpkgs ships 1.27.0 but ghidra-mcp-bridge requires >=1.28.1,<2.0.0.
# Same dependency set as the upstream nixpkgs derivation; version bump only.
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  hatchling,
  uv-dynamic-versioning,

  # runtime deps (same as nixpkgs mcp)
  anyio,
  httpx,
  httpx-sse,
  jsonschema,
  pydantic,
  pydantic-settings,
  pyjwt,
  python-multipart,
  sse-starlette,
  starlette,
  uvicorn,
  typing-extensions,
  typing-inspection,
}:

buildPythonPackage {
  pname = "mcp";
  version = "1.28.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "modelcontextprotocol";
    repo = "python-sdk";
    tag = "v1.28.1";
    hash = "sha256-8nifuun7ShtniimsFr9gYPpjwZEM/5E51GDmZRxQGEc=";
  };

  build-system = [
    hatchling
    uv-dynamic-versioning
  ];

  # Relax pinned version constraints from upstream to match what's in nixpkgs
  pythonRelaxDeps = [
    "pydantic-settings"
    "anyio"
  ];

  dependencies = [
    anyio
    httpx
    httpx-sse
    jsonschema
    pydantic
    pydantic-settings
    pyjwt
    python-multipart
    sse-starlette
    starlette
    uvicorn
    typing-extensions
    typing-inspection
  ];

  # Skip tests — this is a version-bump override, not the primary package
  doCheck = false;
  pythonImportsCheck = [ "mcp" ];

  meta = {
    description = "Official Python SDK for Model Context Protocol servers and clients";
    homepage = "https://github.com/modelcontextprotocol/python-sdk";
    changelog = "https://github.com/modelcontextprotocol/python-sdk/releases/tag/v1.28.1";
    license = lib.licenses.mit;
  };
}
