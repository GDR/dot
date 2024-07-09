{ config, options, lib, ... }: with lib;
let
  cfg = config.modules.darwin.utils.raycast;
in
{
  options.modules.darwin.utils.raycast = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    homebrew = {
        casks = [
            "raycast"
        ];
    };
  };
}