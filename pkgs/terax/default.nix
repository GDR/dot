{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  gtk3,
  gdk-pixbuf,
  cairo,
  glib,
  webkitgtk_4_1,
  libsoup_3,
  libgcc,
  gst_all_1,
}:

let
  version = "0.9.0";

  sources = {
    x86_64-linux = fetchurl {
      url = "https://github.com/crynta/terax-ai/releases/download/v${version}/Terax_${version}_amd64.deb";
      hash = "sha256-f38GUryeYZXU/+GsFMQVM1o9K55ak2Ig8YiGzRQPffU=";
    };
    aarch64-darwin = fetchurl {
      url = "https://github.com/crynta/terax-ai/releases/download/v${version}/Terax_${version}_aarch64.app.tar.gz";
      hash = "sha256-e4YYP7nI00danY9ApO+4mIPrkXtRGTiNJu1L9K2CRCE=";
    };
  };

  inherit (stdenv.hostPlatform) isLinux system;
in

stdenv.mkDerivation {
  pname = "terax";
  inherit version;

  src = sources.${system} or (throw "terax: unsupported platform ${system}");

  nativeBuildInputs = lib.optionals isLinux [
    dpkg
    autoPatchelfHook
    wrapGAppsHook3
  ];

  buildInputs = lib.optionals isLinux [
    gtk3
    gdk-pixbuf
    cairo
    glib
    webkitgtk_4_1
    libsoup_3
    libgcc
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
  ];

  unpackPhase =
    if isLinux then
      ''
        runHook preUnpack
        dpkg-deb -x $src .
        runHook postUnpack
      ''
    else
      ''
        runHook preUnpack
        tar -xzf $src
        runHook postUnpack
      '';

  installPhase =
    if isLinux then
      ''
        runHook preInstall
        mkdir -p $out/bin $out/share
        cp -r usr/share/* $out/share/
        install -Dm755 usr/bin/terax $out/bin/terax
        runHook postInstall
      ''
    else
      ''
        runHook preInstall
        mkdir -p $out/Applications
        cp -r *.app $out/Applications/
        runHook postInstall
      '';

  preFixup = lib.optionalString isLinux ''
    gappsWrapperArgs+=(
      --prefix GST_PLUGIN_SYSTEM_PATH : "${
        lib.makeSearchPath "lib/gstreamer-1.0" [
          gst_all_1.gst-plugins-base
          gst_all_1.gst-plugins-good
          gst_all_1.gst-plugins-bad
        ]
      }"
    )
  '';

  meta = {
    description = "Open-source lightweight cross-platform AI-native terminal (ADE)";
    homepage = "https://terax.app";
    license = lib.licenses.asl20;
    mainProgram = "terax";
    platforms = builtins.attrNames sources;
  };
}
