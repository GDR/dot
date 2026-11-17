#!/bin/sh
# Screenshot script for Hyprland
# Usage: hypr-screenshot [region|full]
set -e

DIR="$HOME/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/$(date +%Y%m%d_%H%M%S).png"

case "${1:-region}" in
  region)
    grim -g "$(slurp)" "$FILE"
    ;;
  full)
    # Capture only the focused monitor
    MONITOR=$(hyprctl activeworkspace -j | grep -o '"monitor":"[^"]*"' | cut -d'"' -f4)
    grim -o "$MONITOR" "$FILE"
    ;;
esac

wl-copy < "$FILE"
