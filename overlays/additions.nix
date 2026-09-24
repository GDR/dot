# Custom packages and flake inputs
{ inputs, system, ... }:

final: _prev:
(import ../pkgs { inherit system; pkgs = final; }) // {
  charon-key = inputs.charon-key.packages.${system}.default;
  clavis = if inputs ? clavis && inputs.clavis ? packages.${system} then inputs.clavis.packages.${system}.default else null;

  # Antigravity 2.x packages from the upstream flake
  google-antigravity = inputs.antigravity-nix.packages.${system}.google-antigravity;
  google-antigravity-ide = inputs.antigravity-nix.packages.${system}.google-antigravity-ide;
  google-antigravity-cli = inputs.antigravity-nix.packages.${system}.google-antigravity-cli;
  antigravity-cli = inputs.antigravity-nix.packages.${system}.google-antigravity-cli;
}
