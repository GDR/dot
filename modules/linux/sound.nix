{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.linux.sound;
in
{
  options.modules.linux.sound = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    # sound.enable = true;
    services.pulseaudio = {
      enable = false;
      support32Bit = true;
      extraConfig = "load-module module-combine-sink";
    };
    user.packages = with pkgs; [
      pavucontrol
    ];
  };
}
