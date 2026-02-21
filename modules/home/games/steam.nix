# Steam gaming platform - Linux only (system-wide when any user enables "games" tag)
{ lib, pkgs, ... }@args: with lib;

lib.my.mkModuleV2 args {
  platforms = [ "linux" ];
  description = "Steam gaming platform with Gamescope support";
  requires = [ "systemLinux.graphics.nvidia" ]; # Better gaming with proper GPU drivers
  extraOptions = {
    enableGamescope = mkOption {
      default = true;
      type = types.bool;
      description = "Whether to enable Gamescope support for Steam";
    };

    remotePlayOpenFirewall = mkOption {
      default = true;
      type = types.bool;
      description = "Open ports in the firewall for Steam Remote Play";
    };

    dedicatedServerOpenFirewall = mkOption {
      default = true;
      type = types.bool;
      description = "Open ports in the firewall for Source Dedicated Server";
    };

    extraCodecs = mkOption {
      default = true;
      type = types.bool;
      description = "Add GStreamer plugins (H.265/HEVC, etc.) to Steam FHS for codec playback";
    };
  };
  systemModule = cfg: {
    nixosSystems = {
      # Enable the Steam program itself (system-level)
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = cfg.remotePlayOpenFirewall;
        dedicatedServer.openFirewall = cfg.dedicatedServerOpenFirewall;
        gamescopeSession.enable = cfg.enableGamescope;
        extraPackages = with pkgs; (optionals cfg.enableGamescope [
          gamescope
          xorg.libXcursor
          xorg.libXi
          xorg.libXinerama
          xorg.libXScrnSaver
          libpng
          libpulseaudio
          libvorbis
          libkrb5
          keyutils
        ]) ++ (optionals cfg.extraCodecs [
          gst_all_1.gst-plugins-bad # H.265/HEVC
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

      # Enable Gamescope as a system program
      programs.gamescope = mkIf cfg.enableGamescope {
        enable = true;
        capSysNice = mkForce false;
      };

      # Hardware-specific support
      hardware.steam-hardware.enable = true;

      # Allow unfree packages for Steam
      nixpkgs.config.allowUnfreePredicate = pkg:
        builtins.elem (getName pkg) [
          "steam"
          "steam-original"
          "steam-run"
        ];
    };
  };
  module = { }; # Steam is system-level only, no home-manager config
}
