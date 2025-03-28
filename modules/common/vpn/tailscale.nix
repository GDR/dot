{ config, options, pkgs, lib, system, ... }: with lib;
let
  cfg = config.modules.common.vpn.tailscale;
  mkModule = lib.my.mkModule system;
in
{
  options.modules.common.vpn.tailscale = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable (mkModule {
    darwin = {
      homebrew = {
        casks = [
          "tailscale"
        ];
      };
    };
  });
}
