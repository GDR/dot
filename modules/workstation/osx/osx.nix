{ config, options, lib, ... }: with lib;
let
  cfg = config.modules.workstation.osx;
in
{
  options.modules.workstation.osx = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    # homebrew = {
    #   enable = true;
    #   onActivation.autoUpdate = false; 
    # };
  };
}
