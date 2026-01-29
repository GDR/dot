# Nix settings - cross-platform system module
{ config, lib, ... }: with lib;
let
  cfg = config.systemAll.nix-settings;
in
{
  options.systemAll.nix-settings = {
    enable = mkEnableOption "common Nix settings (flakes, nix-command)";
  };

  config = mkIf cfg.enable {
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    system.stateVersion = "25.11";
  };
}
