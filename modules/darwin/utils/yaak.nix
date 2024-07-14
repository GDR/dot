{ config, options, lib, pkgs, ... }: with lib;
let
  cfg = config.modules.darwin.utils.yaak;
in
{
  options.modules.darwin.utils.yaak = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    homebrew = {
        casks = [
            "yaak"
        ];
    };
  };
}