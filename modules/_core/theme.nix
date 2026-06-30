# Global theme configuration
# Declares the system-wide theme option consumed by all modules via lib.my.getTheme config
#
# Usage in host config (e.g., hosts/machines/nix-goldstar/default.nix):
#   theme.name = "rose-pine-moon";
#
# Usage in any module:
#   let t = lib.my.getTheme config; in
#   { color = t.roles.accent; }
{ lib, ... }:

{
  options.theme = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "rose-pine-moon";
      description = ''
        Name of the active color theme.
        Must match a file in lib/themes/<name>.nix.
        Available: rose-pine-moon (add more in lib/themes/default.nix)
      '';
    };
  };
}
