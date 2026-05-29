# Antigravity overlay — no-op passthrough.
#
# Antigravity 2.x packages (google-antigravity, google-antigravity-ide,
# google-antigravity-cli) are injected into pkgs via overlays/additions.nix
# using inputs.antigravity-nix.packages.${system}.*.
#
# The old local information.json pin (Antigravity 1.x IDE) is superseded
# by the upstream flake input. This overlay is retained for structural
# consistency but performs no overrides.
{ lib, system, ... }:

_final: _prev: { }
