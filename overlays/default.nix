# This file defines overlays
{ inputs, system, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: (import ../pkgs { inherit system; pkgs = final; }) // {
    charon-key = inputs.charon-key.packages.${system}.default;
  };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev:
    {
      # Override Ollama to version 0.11.3
      ollama = prev.ollama.overrideAttrs (_oldAttrs: {
        version = "0.11.3";
        src = final.fetchFromGitHub {
          owner = "ollama";
          repo = "ollama";
          rev = "v0.11.3";
          hash = "sha256-FghgCtVQIxc9qB5vZZlblugk6HLnxoT8xanZK+N8qEc=";
        };
        vendorHash = "sha256-SlaDsu001TUW+t9WRp7LqxUSQSGDF1Lqu9M1bgILoX4=";
      });
    }
    // (import ./code-cursor/code-cursor.nix { lib = final.lib; system = system; } final prev);
}
