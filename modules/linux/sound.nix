{ config, options, pkgs, lib, ... }: with lib;
let 
  cfg = config.modules.linux.sound; 
in {
  options.modules.linux.sound = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    sound.enable = true;
    hardware.pulseaudio.enable = true;
    hardware.pulseaudio.support32Bit = true;
    hardware.pulseaudio.extraConfig = "load-module module-combine-sink";
    user.packages = with pkgs; [
      pavucontrol
    ];
  };
}