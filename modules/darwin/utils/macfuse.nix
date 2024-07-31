{ config, options, lib, pkgs, ... }: with lib;
let
  cfg = config.modules.darwin.utils.macfuse;
in
{
  options.modules.darwin.utils.macfuse = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      "macfuse"
    ];
  };
}
