# omarchy-waybar — Omarchy scripts & indicators for Waybar (NixOS port)
#
# Fetches the upstream omarchy repo and makes the bin/ scripts + default/waybar/
# indicator scripts available at $OMARCHY_PATH so the V3.1b waybar config works
# without a real Omarchy installation.
#
# Scripts required by config.jsonc:
#   Bins: omarchy-menu, omarchy-update-available, omarchy-capture-screenrecording,
#         omarchy-launch-floating-terminal-with-presentation,
#         omarchy-launch-or-focus-tui, omarchy-launch-wifi, omarchy-launch-audio,
#         omarchy-launch-bluetooth, omarchy-battery-status,
#         omarchy-toggle-idle, omarchy-toggle-notification-silencing,
#         omarchy-voxtype-status, omarchy-voxtype-config, omarchy-voxtype-model,
#         omarchy-tz-select
#   Indicators: $OMARCHY_PATH/default/waybar/indicators/{idle,screen-recording,notification-silencing}.sh
#
{ lib, pkgs, ... }@args:

let
  # ── Fetch omarchy from GitHub ─────────────────────────────────────────────
  # Update hash by running:
  #   nix-prefetch-url --unpack https://github.com/basecamp/omarchy/archive/master.tar.gz
  omarchy = pkgs.fetchFromGitHub {
    owner = "basecamp";
    repo = "omarchy";
    rev = "master";
    hash = "sha256-tnAFBxdXamEG2qAy4TVUB8dSQrGVUjlQPE42lK4aoiY=";
  };

  # ── Build a derivation that puts all omarchy scripts in $out/bin ──────────
  # Copies every omarchy-* script from bin/ and makes them executable.
  # No compilation needed — they are plain shell / ruby scripts.
  omarchyBins = pkgs.runCommand "omarchy-bins"
    {
      # Make common runtime tools available on PATH inside the scripts
      nativeBuildInputs = [ pkgs.makeWrapper ];
    }
    ''
      mkdir -p $out/bin

      for f in ${omarchy}/bin/omarchy-*; do
        install -m 755 "$f" $out/bin/
      done
    '';

in
lib.my.mkModuleV2 args {
  platforms = [ "linux" ];
  description = "Omarchy scripts & waybar indicators (NixOS port)";

  module = {
    nixosSystems = {
      # ── Runtime packages required by omarchy scripts ────────────────────
      home.packages = with pkgs; [
        omarchyBins # all omarchy-* scripts on $PATH

        # omarchy-launch-or-focus-tui btop  (cpu / memory on-click)
        btop

        # omarchy-launch-wifi  → nmtui / nm-connection-editor
        networkmanagerapplet

        # omarchy-launch-audio / omarchy-launch-bluetooth
        pavucontrol
        blueman

        # omarchy-capture-screenrecording  → wf-recorder + slurp for region
        wf-recorder
        slurp

        # omarchy-battery-status (reads upower for time-remaining)
        upower

        # custom/weather module
        wttrbar

        # pulseaudio#input/output modules
        pamixer
        pulseaudio # provides pactl

        # xdg-terminal-exec (on-click-right for the omarchy button)
        xdg-terminal-exec
      ];

      # ── Inject OMARCHY_PATH into the user session ────────────────────────
      # Waybar indicator execs reference $OMARCHY_PATH/default/waybar/indicators/*.sh
      # home.sessionVariables writes to ~/.profile / PAM env so waybar picks it up.
      home.sessionVariables = {
        OMARCHY_PATH = "${omarchy}";
      };
    };
  };
}
