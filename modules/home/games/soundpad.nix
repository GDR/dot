# Soundpad — Virtual mic soundboard for Dota 2
#
# Creates a PipeWire virtual sink/source pair so sound effects play
# through a virtual microphone that Dota 2 teammates hear in voice chat.
#
# Quick start:
#   1. Deploy and restart PipeWire (or reboot)
#   2. Drop sounds as 1.wav, 2.wav, ... 12.wav in ~/.config/soundpad/sounds/
#   3. Set "Soundpad Mic" as input device in Dota 2 / Discord
#   4. Press F1–F12 (Fn+F1–F12 on Keychron) to play sounds
#   5. Optional: run `soundpad setup` to also pass your real mic through
{ lib, pkgs, ... }@args:

let
  soundpad = pkgs.writeShellScriptBin "soundpad" ''
    SOUNDS_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/soundpad/sounds"
    RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    PID_FILE="$RUNTIME_DIR/soundpad-play.pid"
    LOOPBACK_FILE="$RUNTIME_DIR/soundpad-loopback.id"

    mkdir -p "$SOUNDS_DIR"

    # Kill any currently playing sound
    kill_current() {
      if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null || true)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
          # Kill children (paplay) first, then the subshell
          ${pkgs.procps}/bin/pkill -P "$pid" 2>/dev/null || true
          kill "$pid" 2>/dev/null || true
        fi
        rm -f "$PID_FILE"
      fi
      # Kill any lingering speaker playback
      ${pkgs.procps}/bin/pkill -f "paplay.*--volume=" 2>/dev/null || true
    }

    case "''${1:-help}" in
      setup)
        # Start mic passthrough: real mic → soundpad sink → soundpad mic
        if [ -f "$LOOPBACK_FILE" ]; then
          echo "Mic passthrough already active (module $(cat "$LOOPBACK_FILE"))."
          exit 0
        fi
        default_source=$(${pkgs.pulseaudio}/bin/pactl get-default-source)
        module_id=$(${pkgs.pulseaudio}/bin/pactl load-module module-loopback \
          source="$default_source" sink=soundpad_sink latency_msec=30)
        echo "$module_id" > "$LOOPBACK_FILE"
        echo "Mic passthrough started (module $module_id)."
        echo "Voice + sounds now go through 'Soundpad Mic'."
        ;;

      teardown)
        # Stop mic passthrough
        if [ -f "$LOOPBACK_FILE" ]; then
          ${pkgs.pulseaudio}/bin/pactl unload-module "$(cat "$LOOPBACK_FILE")" 2>/dev/null || true
          rm -f "$LOOPBACK_FILE"
          echo "Mic passthrough stopped."
        else
          echo "No mic passthrough running."
        fi
        ;;

      stop)
        kill_current
        ;;

      status)
        echo "=== Soundpad Status ==="
        echo "Sounds: $SOUNDS_DIR"
        echo ""
        if compgen -G "$SOUNDS_DIR/*" > /dev/null 2>&1; then
          echo "Available:"
          ls -1 "$SOUNDS_DIR" 2>/dev/null | sed 's/^/  /'
        else
          echo "No sounds found. Add 1.wav, 2.wav, etc. to $SOUNDS_DIR"
        fi
        echo ""
        if [ -f "$LOOPBACK_FILE" ] && ${pkgs.pulseaudio}/bin/pactl list modules short 2>/dev/null | grep -q "$(cat "$LOOPBACK_FILE")"; then
          echo "Mic passthrough: active"
        else
          rm -f "$LOOPBACK_FILE" 2>/dev/null || true
          echo "Mic passthrough: off (run 'soundpad setup')"
        fi
        ;;

      [0-9]|[0-9][0-9])
        # Play sound N through the virtual sink
        # Supports variants: 1.wav, 1_a.wav, 1_2.wav — picks randomly
        sound_num="$1"
        candidates=()
        for ext in wav mp3 ogg flac opus; do
          # Exact match: N.ext
          [ -f "$SOUNDS_DIR/''${sound_num}.''${ext}" ] && \
            candidates+=("$SOUNDS_DIR/''${sound_num}.''${ext}")
          # Variants: N_*.ext
          for f in "$SOUNDS_DIR/''${sound_num}_"*".''${ext}"; do
            [ -f "$f" ] && candidates+=("$f")
          done
        done

        # No matching file — silent exit
        [ ''${#candidates[@]} -eq 0 ] && exit 0

        # Avoid repeating the same sound twice in a row
        LAST_FILE="$RUNTIME_DIR/soundpad-last-$sound_num"
        last_played=$(cat "$LAST_FILE" 2>/dev/null || true)
        if [ ''${#candidates[@]} -gt 1 ] && [ -n "$last_played" ]; then
          # Remove last played from candidates
          filtered=()
          for c in "''${candidates[@]}"; do
            [ "$c" != "$last_played" ] && filtered+=("$c")
          done
          candidates=("''${filtered[@]}")
        fi

        # Pick a random file
        sound_file="''${candidates[$((RANDOM % ''${#candidates[@]}))]}"
        echo "$sound_file" > "$LAST_FILE"

        kill_current

        # Hold push-to-talk (G=keycode 34), play sound, release G
        (
          ${pkgs.ydotool}/bin/ydotool key 34:1
          ${pkgs.pulseaudio}/bin/paplay --volume=81920 --device=soundpad_sink "$sound_file"
          ${pkgs.ydotool}/bin/ydotool key 34:0
        ) &
        echo $! > "$PID_FILE"
        # Also play to speakers at 50% (you hear this)
        ${pkgs.pulseaudio}/bin/paplay --volume=32768 "$sound_file" &
        disown
        ;;

      help|--help|-h)
        echo "soundpad — virtual mic soundboard"
        echo ""
        echo "Usage:"
        echo "  soundpad <N>         Play sound N (matches N.wav, N.mp3, etc.)"
        echo "  soundpad stop        Stop current sound"
        echo "  soundpad setup       Enable mic passthrough (voice + sounds)"
        echo "  soundpad teardown    Disable mic passthrough"
        echo "  soundpad status      Show status and available sounds"
        echo ""
        echo "Sounds dir: $SOUNDS_DIR"
        ;;

      *)
        echo "Unknown: $1 (try 'soundpad help')" >&2
        exit 1
        ;;
    esac
  '';

in
lib.my.mkModuleV2 args {
  platforms = [ "linux" ];
  description = "Virtual mic soundboard for Dota 2";
  requires = [ "systemLinux.sound" ];

  module = {
    nixosSystems = {
      home.packages = [
        soundpad
        pkgs.ydotool
      ];

      # ydotoold daemon — creates a permanent virtual keyboard.
      # Starts at login so Dota sees it as an existing device, not a new controller.
      systemd.user.services.ydotoold = {
        Unit.Description = "ydotool virtual input daemon";
        Service = {
          ExecStart = "${pkgs.ydotool}/bin/ydotoold";
          Restart = "always";
          RestartSec = 2;
        };
        Install.WantedBy = [ "default.target" ];
      };

      # PipeWire virtual sink → source loopback (auto-created on PipeWire start).
      # "Soundpad Sink" receives played audio, "Soundpad Mic" appears as a mic.
      xdg.configFile."pipewire/pipewire.conf.d/20-soundpad.conf".text = ''
        context.modules = [
          {
            name = libpipewire-module-loopback
            args = {
              node.description = "Soundpad Loopback"
              capture.props = {
                media.class      = "Audio/Sink"
                node.name        = "soundpad_sink"
                node.description = "Soundpad Sink"
                audio.position   = [ FL FR ]
              }
              playback.props = {
                media.class      = "Audio/Source"
                node.name        = "soundpad_mic"
                node.description = "Soundpad Mic"
                audio.position   = [ FL FR ]
              }
            }
          }
        ]
      '';
    };
  };
}
