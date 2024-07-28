{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.browsers.firefox;
in
{
  options.modules.common.browsers.firefox = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      "firefox"
    ];
  };
}
