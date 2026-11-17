# Nix settings - cross-platform system module
{ lib, ... }@args:

lib.my.mkSystemModuleV2 args {
  namespace = "all";
  description = "Common Nix settings (flakes, nix-command)";

  module = _: {
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
  };
}
