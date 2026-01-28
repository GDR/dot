{ config, options, pkgs, lib, ... }: with lib;
let
  mod = lib.my.modulePath [ "common" "utils" "nix-essentials" ] config;
  cfg = mod.cfg;
in
{

  options.modules.common.utils.nix-essentials = with types; {
    enable = mkOption {
      default = true;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      nixpkgs-fmt
    ];
  };
}
