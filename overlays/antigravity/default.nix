# Antigravity editor overlay
{ lib, system, ... }:

final: prev:
let
  inherit (prev.stdenv) hostPlatform;

  information = lib.importJSON ./information.json;
  sourceInfo = information.sources.${hostPlatform.system};

  pname = "antigravity";
  version = information.version;
  vscodeVersion = information.vscodeVersion;
in
{
  antigravity = prev.antigravity.overrideAttrs (_oldAttrs: {
    inherit version vscodeVersion;

    src = prev.fetchurl {
      inherit (sourceInfo) url;
      sha256 = sourceInfo.sha256;
    };
  });
}