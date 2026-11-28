{
  lib,
  stdenv,
  pkg-config,
  wayland,
  wayland-protocols,
  wayland-scanner,
  wlr-protocols,
  cairo,
}:

stdenv.mkDerivation {
  pname = "hypr-drag-hint";
  version = "0.2.0";

  src = ./src;

  nativeBuildInputs = [
    pkg-config
    wayland-scanner
  ];

  buildInputs = [
    wayland
    wayland-protocols
    wlr-protocols
    cairo
  ];

  buildPhase = ''
    runHook preBuild

    WAYLAND_PROTOCOLS_DIR=$(pkg-config --variable=pkgdatadir wayland-protocols)
    WLR_PROTOCOLS_DIR=$(pkg-config --variable=pkgdatadir wlr-protocols)

    wayland-scanner client-header \
      "$WAYLAND_PROTOCOLS_DIR/stable/xdg-shell/xdg-shell.xml" \
      xdg-shell-client-protocol.h
    wayland-scanner private-code \
      "$WAYLAND_PROTOCOLS_DIR/stable/xdg-shell/xdg-shell.xml" \
      xdg-shell-protocol.c

    wayland-scanner client-header \
      "$WLR_PROTOCOLS_DIR/unstable/wlr-layer-shell-unstable-v1.xml" \
      wlr-layer-shell-unstable-v1-client-protocol.h
    wayland-scanner private-code \
      "$WLR_PROTOCOLS_DIR/unstable/wlr-layer-shell-unstable-v1.xml" \
      wlr-layer-shell-unstable-v1-protocol.c

    $CC -O2 -Wall -Wextra -std=gnu11 \
      -I. \
      main.c \
      xdg-shell-protocol.c \
      wlr-layer-shell-unstable-v1-protocol.c \
      -o hypr-drag-hint \
      $(pkg-config --cflags --libs wayland-client cairo) \
      -lm

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 hypr-drag-hint "$out/bin/hypr-drag-hint"
    runHook postInstall
  '';

  meta = {
    description = "Wayland layer-shell animated layout preview overlay for Hyprland";
    platforms = lib.platforms.linux;
    mainProgram = "hypr-drag-hint";
  };
}
