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
https://ru.wikipedia.org/wiki/%D0%93%D0%B4%D0%B5_%D0%BD%D0%B0%D1%85%D0%BE%D0%B4%D0%B8%D1%82%D1%81%D1%8F_%D0%BD%D0%BE%D1%84%D0%B5%D0%BB%D0%B5%D1%82%3F