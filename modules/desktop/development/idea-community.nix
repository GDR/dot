{ config, options, lib, ... }: with lib;
let
  cfg = config.modules.desktop.development.idea;
in {
  options.modules.desktop.development.idea = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
  };
}
