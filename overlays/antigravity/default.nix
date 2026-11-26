# Antigravity overlay
#
# 1. Fixes DMG unpacking on Darwin/macOS where upstream Google Antigravity 2.9+
#    switched DMG format from HFS+ to APFS (7zz unpacks APFS DMGs reliably).
# 2. Pins ahead of jacopone/antigravity-nix when Google's release feed
#    (https://antigravity-hub-auto-updater-974169037036.us-central1.run.app/releases)
#    has a newer build than the upstream flake's daily cron; steps aside
#    automatically once upstream catches up or surpasses `appPin.version`.
# 3. Wraps `google-antigravity-cli` (`agy`) in `buildFHSEnv` on Linux so its
#    built-in `sbox` sandbox (`pivot_root` + `exec /proc/self/exe`) succeeds on
#    NixOS instead of exiting with `sbox: exec /proc/self/exe: no such file or
#    directory` (which surfaces as `connecting to sandbox server: ... connection
#    reset by peer`).
{ lib, system, ... }:

final: prev:
let
  appPin = {
    version = "2.32.2-4665802025205760";
    sources = {
      aarch64-darwin = {
        url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/2.32.2-4665802025205760/darwin-arm/Antigravity.dmg";
        hash = "sha256-OuTmH/+NzBwnG7VTYH5zilslchleLfByYK0nQ9k0Tzg=";
      };
      x86_64-linux = {
        url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/2.32.2-4665802025205760/linux-x64/Antigravity.tar.gz";
        hash = "sha256-Iz2QzI20j0oJ+KBXW2vA38C7RvFVIX2J4bDl/R14AjU=";
      };
    };
  };

  fixDarwinDmg =
    pkg:
    if prev.stdenv.hostPlatform.isDarwin && (pkg ? overrideAttrs) then
      pkg.overrideAttrs (oldAttrs: {
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

  bumpedApp =
    let
      srcInfo = appPin.sources.${system} or null;
      shouldBump =
        srcInfo != null
        && (prev.google-antigravity ? override)
        && lib.versionOlder (prev.google-antigravity.version or "0") appPin.version;
    in
    if shouldBump then
      (prev.google-antigravity.override {
        srcOverride = final.fetchurl srcInfo;
      }).overrideAttrs
        {
          inherit (appPin) version;
          # `src` is already swapped via `srcOverride` above (supporting Linux FHS wrapper).
          __intentionallyOverridingVersion = true;
        }
    else
      prev.google-antigravity;
  wrappedCli =
    if prev.stdenv.hostPlatform.isLinux then
      let
        cliPkg = prev.google-antigravity-cli;
        cliFhs = final.buildFHSEnv {
          name = "google-antigravity-cli-fhs";
          targetPkgs = p: [
            p.bashInteractive
            p.coreutils
            p.glibc
          ];
          extraBwrapArgs = [
            "--bind-try /etc/nixos/ /etc/nixos/"
            "--ro-bind-try /etc/xdg/ /etc/xdg/"
            "--ro-bind-try /etc/nixpkgs/ /etc/nixpkgs/"
          ];
          runScript = "${cliPkg}/bin/agy";
        };
      in
      final.stdenv.mkDerivation {
        pname = cliPkg.pname or "google-antigravity-cli";
        version = cliPkg.version or "0";
        dontUnpack = true;
        dontBuild = true;
        installPhase = ''
          mkdir -p $out/bin
          ln -s ${cliFhs}/bin/google-antigravity-cli-fhs $out/bin/agy
        '';
        meta = (cliPkg.meta or { }) // {
          mainProgram = "agy";
        };
      }
    else
      prev.google-antigravity-cli;
in
{
  google-antigravity = fixDarwinDmg bumpedApp;
  google-antigravity-ide = fixDarwinDmg prev.google-antigravity-ide;
  google-antigravity-cli = wrappedCli;
  antigravity-cli = wrappedCli;
}
