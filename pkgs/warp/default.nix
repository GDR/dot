{
  lib,
  stdenvNoCC,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  _7zz,
  alsa-lib,
  curl,
  fontconfig,
  libglvnd,
  libxkbcommon,
  vulkan-loader,
  wayland,
  xdg-utils,
  libxi,
  libxcursor,
  libx11,
  libxcb,
  xz,
  zlib,
  makeWrapper,
  waylandSupport ? true,
}:

let
  pname = "warp-terminal";
  version = "0.2026.11.18.08.17.stable_06";
  debVersion = builtins.replaceStrings [ "_" ] [ "." ] version;

  meta = {
    description = "Rust-based terminal";
    homepage = "https://www.warp.dev";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "warp-terminal";
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
  };

  linux = stdenv.mkDerivation {
    inherit pname version meta;

    src = fetchurl {
      url = "https://releases.warp.dev/stable/v${version}/warp-terminal_${debVersion}_amd64.deb";
      hash = "sha256-VaT/vc1P34sGJkge/26kNUvmee4KoyucE9ay/5IErfY=";
    };

    nativeBuildInputs = [
      dpkg
      autoPatchelfHook
      makeWrapper
    ];

    buildInputs = [
      alsa-lib
      curl
      fontconfig
      (lib.getLib stdenv.cc.cc)
      zlib
      xz
    ];

    runtimeDependencies = [
      libglvnd
      libxkbcommon
      stdenv.cc.libc
      vulkan-loader
      xdg-utils
      libx11
      libxcb
      libxcursor
      libxi
    ]
    ++ lib.optionals waylandSupport [ wayland ];

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb -x $src .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp -r opt usr/* $out
      makeWrapper $out/opt/warpdotdev/warp-terminal/warp $out/bin/warp-terminal \
        ${lib.optionalString waylandSupport "--set WARP_ENABLE_WAYLAND 1"}

      runHook postInstall
    '';

    postFixup = ''
      # Link missing libfontconfig to fix font discovery
      patchelf \
        --add-needed libfontconfig.so.1 \
        $out/opt/warpdotdev/warp-terminal/warp
    '';
  };

  darwin = stdenvNoCC.mkDerivation {
    inherit pname version meta;

    src = fetchurl {
      url = "https://releases.warp.dev/stable/v${version}/Warp.dmg";
      hash = "sha256-KyG5CjAQpyS6+fWjof+X40xTjFBdCYtvlDnnVbf1T7E=";
    };

    sourceRoot = ".";

    # Warp.dmg is APFS formatted, which is unsupported by undmg
    nativeBuildInputs = [ _7zz ];

    # Warp.app ships signed and notarized; rewriting shebangs breaks the code signature seal
    dontPatchShebangs = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/Applications
      cp -r *.app $out/Applications

      runHook postInstall
    '';
  };
in
if stdenvNoCC.hostPlatform.isDarwin then darwin else linux
