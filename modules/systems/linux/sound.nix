# Sound/Audio - Linux system module (PipeWire)
{ lib, pkgs, config, ... }@args:

let
  enabledUsers = lib.filterAttrs (_: u: u.enable) config.hostUsers;
in
lib.my.mkSystemModuleV2 args {
  namespace = "linux";
  description = "PipeWire audio with ALSA and PulseAudio emulation";

  module = _: {
    # Enable PipeWire with ALSA and Pulse emulation
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    # Keep manually selected default sink instead of auto-restoring
    # previously active device/routes (helps with game audio rerouting).
    environment.etc."wireplumber/wireplumber.conf.d/10-default-audio.conf".text = ''
      wireplumber.settings = {
        "device.restore-profile" = false
        "device.restore-routes" = false
      }
    '';

    # Realtime priority for audio
    security.rtkit.enable = true;

    # Audio control apps for users
    home-manager.users = lib.mapAttrs
      (name: _: {
        home.packages = with pkgs; [
          pavucontrol
          pulseaudio
        ];
      })
      enabledUsers;
  };
}
