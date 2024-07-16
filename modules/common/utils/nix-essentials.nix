{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.utils.nix-essentials;
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
