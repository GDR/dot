{ config, options, lib, pkgs, ... }: with lib;
let
  cfg = config.modules.darwin.ide.xcode;
in
{
  options.modules.darwin.ide.xcode = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = {
    homebrew.masApps = if cfg.enable then { xcode = 497799835; } else { };
  };
}
