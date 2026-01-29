# Nix garbage collection - cross-platform system module
{ config, pkgs, lib, ... }: with lib;
let
  isDarwin = pkgs.stdenv.isDarwin;
  cfg = config.systemAll.nix-gc;
in
{
  options.systemAll.nix-gc = {
    enable = mkEnableOption "automatic Nix garbage collection";

    olderThan = mkOption {
      type = types.str;
      default = "30d";
      description = "Delete generations older than this";
    };
  };

  config = mkIf cfg.enable {
    nix.gc = {
      automatic = true;
      options = "--delete-older-than ${cfg.olderThan}";
    } // (if isDarwin then {
      # Darwin uses interval (weekly = every 7 days)
      interval = { Weekday = 0; Hour = 3; Minute = 0; };
    } else {
      # NixOS uses dates
      dates = "weekly";
    });
  };
}
