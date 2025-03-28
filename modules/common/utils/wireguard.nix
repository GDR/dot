{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.utils.wireguard;
in
{
  options.modules.common.utils.wireguard = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      wireguard-tools
    ];
  };

}
