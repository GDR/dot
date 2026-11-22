#!/bin/sh
# Toggle region screen recording for SwayNC buttons-grid
set -e

if pgrep -x wf-recorder >/dev/null 2>&1; then
  pkill -INT -x wf-recorder
  notify-send -a "Screen Recording" "Recording stopped" "Saved to ~/Videos"
  exit 0
fi

DIR="$HOME/Videos"
mkdir -p "$DIR"
FILE="$DIR/recording_$(date +%Y%m%d_%H%M%S).mp4"

GEOM=$(slurp) || exit 0
notify-send -a "Screen Recording" "Recording started" "Click record again to stop"
wf-recorder -g "$GEOM" -f "$FILE"
