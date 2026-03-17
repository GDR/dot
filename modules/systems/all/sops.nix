# SOPS - cross-platform system module
# Installs sops system-wide and wires up the age key path.
#
# OS defaults for SOPS_AGE_KEY_FILE:
#   Linux  → ~/.config/sops/age/keys.txt  (XDG default, works out-of-the-box)
#   macOS  → ~/Library/Application Support/sops/age/keys.txt
#             (non-XDG, so we set the env var explicitly)
{ lib, pkgs, ... }@args:

lib.my.mkSystemModuleV2 args {
  namespace = "all";
  description = "Install sops system-wide and configure age key path";

  # Install sops on all platforms
  module = _: {
    environment.systemPackages = [ pkgs.sops ];
  };

  # macOS: set SOPS_AGE_KEY_FILE explicitly (not XDG-compliant by default).
  # Written into /etc/zshenv + launchctl setenv so every shell sees it.
  moduleDarwin = _: {
    environment.variables.SOPS_AGE_KEY_FILE =
      "$HOME/Library/Application Support/sops/age/keys.txt";
  };
}
