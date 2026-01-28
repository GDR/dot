{ config, options, lib, pkgs, ... }:
with lib;
let
  mod = lib.my.modulePath [ "linux" "games" "steam" ] config;
  cfg = mod.cfg;
in
{

  options.modules.linux.games.steam = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
      description = "Enable Steam gaming platform";
    };

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
  };

  config = mkIf cfg.enable {
    # Enable the Steam program itself
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = cfg.remotePlayOpenFirewall;
      dedicatedServer.openFirewall = cfg.dedicatedServerOpenFirewall;
      gamescopeSession.enable = cfg.enableGamescope;
      # Add gamescope and required libraries to Steam's FHS environment
      # This allows gamescope to be available when launching games with "gamescope -- %command%"
      extraPackages = with pkgs; lib.optionals cfg.enableGamescope [
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
      ];
    };

    # Enable Gamescope as a system program
    programs.gamescope = mkIf cfg.enableGamescope {
      enable = true;
      # Note: capSysNice can cause "failed to inherit capabilities" errors with Steam's FHS
      # Disable it by default when using gamescope with Steam to avoid bwrap capability stripping
      # Using mkForce to ensure this takes precedence when both Steam and Lutris are enabled
      # Steam's FHS environment requires capSysNice = false to work properly
      capSysNice = mkForce false;
    };

    # Hardware-specific support (recommended for better controller support)
    hardware.steam-hardware.enable = true;

    # Allow unfree packages for Steam
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "steam"
        "steam-original"
        "steam-run"
      ];
  };
}
