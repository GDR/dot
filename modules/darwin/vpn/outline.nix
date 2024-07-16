{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.darwin.vpn;
in
{
  options.modules.darwin.vpn.outline-client = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };
  options.modules.darwin.vpn.outline-manager = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = {
    homebrew = {
      casks = if cfg.outline-manager.enable then [ "outline-manager" ] else [ ];
      masApps = if cfg.outline-client.enable then { outline = 1356178125; } else { };
    };
  };
}
