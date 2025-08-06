# This file defines overlays
{ inputs, system, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { inherit system; pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # Override Ollama to version 0.11.3
    ollama = prev.ollama.overrideAttrs (oldAttrs: {
      version = "0.11.3";
      src = final.fetchFromGitHub {
        owner = "ollama";
        repo = "ollama";
        rev = "v0.11.3";
        hash = "sha256-FghgCtVQIxc9qB5vZZlblugk6HLnxoT8xanZK+N8qEc=";
      };
      vendorHash = "sha256-SlaDsu001TUW+t9WRp7LqxUSQSGDF1Lqu9M1bgILoX4=";
    });
    lmstudio = prev.lmstudio.overrideAttrs (oldAttrs: rec {
      version = "0.3.22-1";
      src = final.fetchurl {
        url = "https://installers.lmstudio.ai/linux/x64/0.3.22-1/LM-Studio-0.3.22-1-x64.AppImage";
        hash = "sha256-oqukPQ0kSiBpDIePwSKTC4gpbFmGZ+CaNf7p8z65xAE=";
      };
      passthru = (oldAttrs.passthru or { }) // {
        updateScript = oldAttrs.passthru.updateScript or null;
        nixpkgs-override = "0.3.22-1"; # Force cache invalidation
      };
    });
  };
}
