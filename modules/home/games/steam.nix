# Steam gaming platform - Linux only
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "linux" ];
  description = "Steam gaming platform with Gamescope support";

  extraOptions = {
    enableGamescope = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Whether to enable Gamescope support for Steam";
    };

    remotePlayOpenFirewall = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Open ports in the firewall for Steam Remote Play";
    };

    dedicatedServerOpenFirewall = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Open ports in the firewall for Source Dedicated Server";
    };

    extraCodecs = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Add GStreamer plugins (H.265/HEVC, etc.) to Steam FHS for codec playback";
    };
  };

  nixosModule = { pkgs, lib, featureCfg, ... }:
    let
      enableGamescope = featureCfg.enableGamescope or true;
      remotePlayOpenFirewall = featureCfg.remotePlayOpenFirewall or true;
      dedicatedServerOpenFirewall = featureCfg.dedicatedServerOpenFirewall or true;
      extraCodecs = featureCfg.extraCodecs or true;
    in
    {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = remotePlayOpenFirewall;
        dedicatedServer.openFirewall = dedicatedServerOpenFirewall;
        gamescopeSession.enable = enableGamescope;
        extraPackages = with pkgs; (lib.optionals enableGamescope [
          gamescope
          libxcursor
          libxi
          libxinerama
          libxscrnsaver
          libpng
          libpulseaudio
          libvorbis
          libkrb5
          keyutils
        ]) ++ (lib.optionals extraCodecs [
          gst_all_1.gst-plugins-bad
          gst_all_1.gst-plugins-ugly
          gst_all_1.gst-libav
          gst_all_1.gstreamer
          gst_all_1.gst-plugins-base
          gst_all_1.gst-plugins-good
        ]);
        extraCompatPackages = with pkgs; [
          proton-ge-bin
        ];
      };

      programs.gamescope = lib.mkIf enableGamescope {
        enable = true;
        capSysNice = lib.mkForce false;
      };

      hardware.steam-hardware.enable = true;

      nixpkgs.config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "steam"
          "steam-original"
          "steam-run"
        ];
    };
}
