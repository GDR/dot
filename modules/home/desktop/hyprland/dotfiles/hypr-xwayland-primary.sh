#!/bin/sh
# Set the XWayland primary monitor via xrandr.
# XWayland starts lazily on Hyprland and registers RandR outputs asynchronously,
# so a bare `xrandr --output ... --primary` on startup can race and silently fail.
# Usage: hypr-xwayland-primary.sh [OUTPUT] [MAX_ATTEMPTS] [SLEEP_SECS]
set -eu

OUTPUT="${1:-DP-3}"
MAX_ATTEMPTS="${2:-30}"
SLEEP_SECS="${3:-0.5}"

resolve_display() {
  if [ -n "${DISPLAY:-}" ]; then
    return 0
  fi
  for sock in /tmp/.X11-unix/X*; do
    if [ -S "$sock" ]; then
      DISPLAY=":${sock##*/X}"
      export DISPLAY
      return 0
    fi
  done
  return 1
}

i=0
while [ "$i" -lt "$MAX_ATTEMPTS" ]; do
  if resolve_display; then
    query_out=$(xrandr --query 2>/dev/null || true)
    if printf '%s\n' "$query_out" | grep -q "^${OUTPUT} connected primary"; then
      exit 0
    fi
    if printf '%s\n' "$query_out" | grep -q "^${OUTPUT} connected"; then
      xrandr --output "$OUTPUT" --primary 2>/dev/null || true
      if xrandr --query 2>/dev/null | grep -q "^${OUTPUT} connected primary"; then
        exit 0
      fi
    fi
  fi
  i=$((i + 1))
  sleep "$SLEEP_SECS"
done

echo "hypr-xwayland-primary: timed out waiting for XWayland output '${OUTPUT}'" >&2
exit 1
