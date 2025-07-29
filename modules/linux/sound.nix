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
    # Enable PipeWire with ALSA and Pulse emulation
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true; # PulseAudio emulation
      wireplumber.enable = true; # session manager
    };
    security.rtkit.enable = true; # for realtime priority

    home.packages = with pkgs; [
      pavucontrol
      pulseaudio
    ];
  };
}
