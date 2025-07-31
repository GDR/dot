{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.utils.bitwarden;
in
{
  options.modules.common.utils.bitwarden = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      bitwarden
    ];
  };
}
