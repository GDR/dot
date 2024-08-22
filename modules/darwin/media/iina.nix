{ config, options, lib, pkgs, ... }: with lib;
let
  cfg = config.modules.darwin.media.iina;
in
{
  options.modules.darwin.media.iina = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      iina
    ];
  };
}
