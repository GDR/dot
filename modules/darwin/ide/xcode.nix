{ config, options, lib, pkgs, ... }: with lib;
let
  mod = lib.my.modulePath [ "darwin" "ide" "xcode" ] config;
  cfg = mod.cfg;
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
