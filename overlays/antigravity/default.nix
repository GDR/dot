# Antigravity overlay
#
# Fixes DMG unpacking on Darwin/macOS where upstream Google Antigravity 2.9+
# switched DMG format from HFS+ to APFS, and 7zz extracts DMG root volume folder.
# undmg (which uses hfsplus) fails with "error: only HFS file systems are supported".
# We replace undmg with 7zz and move any extracted *.app to top level.
{ lib, system, ... }:

final: prev:
let
  fixDarwinDmg = pkg:
    if prev.stdenv.hostPlatform.isDarwin && (pkg ? overrideAttrs) then
      pkg.overrideAttrs
        (oldAttrs: {
          nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ final._7zz ];
          unpackPhase = ''
            runHook preUnpack
            7zz x $src
            find . -mindepth 2 -maxdepth 2 -name "*.app" -exec mv {} . \; 2>/dev/null || true
            runHook postUnpack
          '';
        })
    else
      pkg;
in
{
  google-antigravity = fixDarwinDmg prev.google-antigravity;
  google-antigravity-ide = fixDarwinDmg prev.google-antigravity-ide;
}
