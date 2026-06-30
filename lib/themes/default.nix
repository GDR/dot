# Theme registry — loads themes by name
# Usage:
#   lib.my.themes.getTheme "rose-pine-moon"
#   lib.my.themes.availableThemes
{ lib }:

let
  # All available themes (add new themes here)
  themeFiles = {
    "rose-pine-moon" = ./rose-pine-moon.nix;
    # "catppuccin-mocha" = ./catppuccin-mocha.nix;
    # "gruvbox-dark"     = ./gruvbox-dark.nix;
    # "tokyo-night"      = ./tokyo-night.nix;
    # "base2tone-earth"  = ./base2tone-earth.nix;
  };

  # Load a theme by name — throws a clear error if name is unknown
  getTheme = name:
    if themeFiles ? ${name}
    then import themeFiles.${name}
    else
      throw ''
        Unknown theme: "${name}"
        Available themes: ${lib.concatStringsSep ", " (lib.attrNames themeFiles)}
      '';

in
{
  inherit getTheme;
  availableThemes = lib.attrNames themeFiles;
}
