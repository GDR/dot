# Sound/Audio - Linux system module (PipeWire)
{ config, pkgs, lib, ... }: with lib;
let
  cfg = config.systemLinux.sound;
  enabledUsers = filterAttrs (_: u: u.enable) config.hostUsers;
in
{
  options.systemLinux.sound = {
    enable = mkEnableOption "PipeWire audio with ALSA and PulseAudio emulation";
  };

  config = mkIf cfg.enable {
    # Enable PipeWire with ALSA and Pulse emulation
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    # Realtime priority for audio
    security.rtkit.enable = true;

    # Audio control apps for users
    home-manager.users = mapAttrs
      (name: _: {
        home.packages = with pkgs; [
          pavucontrol
          pulseaudio
        ];
      })
      enabledUsers;
  };
}
