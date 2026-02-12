# Cursor editor overlay
{ lib, system, ... }:

final: prev:
let
  inherit (prev.stdenv) hostPlatform;
  sourcesJson = lib.importJSON ./sources.json;
  sources = lib.mapAttrs
    (_: info: prev.fetchurl { inherit (info) url hash; })
    sourcesJson.sources;

  source = sources.${hostPlatform.system};

  pname = "cursor";
  version = sourcesJson.version;
  vscodeVersion = sourcesJson.vscodeVersion;
in
{
  code-cursor = prev.code-cursor.overrideAttrs (_oldAttrs: {
    inherit version vscodeVersion;
    src =
      if hostPlatform.isLinux then
        prev.appimageTools.extract { inherit pname version; src = source; }
      else
        source;
    sourceRoot =
      if hostPlatform.isLinux then
        "${pname}-${version}-extracted/usr/share/cursor"
      else
        _oldAttrs.sourceRoot;
  });
}
