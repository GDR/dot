# Steam gaming platform - Linux only
{ config, pkgs, lib, system, _modulePath, ... }: with lib;
let
  mkModule = lib.my.mkModule system;
  modulePath = _modulePath;
  moduleTags = [ "games" ];

  pathParts = splitString "." modulePath;
  cfg = foldl (acc: part: acc.${part}) config.modules pathParts;
in
{
  meta = lib.my.mkModuleMeta {
    tags = moduleTags;
    platforms = [ "linux" ];
    description = "Steam gaming platform with Gamescope support";
  };

  options = lib.my.mkModuleOptions modulePath {
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

  config =
    let
      shouldEnable = lib.my.shouldEnableModule { inherit config modulePath moduleTags; };
    in
    mkIf shouldEnable (mkModule {
      nixosSystems = {
        # Enable the Steam program itself
        programs.steam = {
          enable = true;
          remotePlay.openFirewall = cfg.remotePlayOpenFirewall;
          dedicatedServer.openFirewall = cfg.dedicatedServerOpenFirewall;
          gamescopeSession.enable = cfg.enableGamescope;
          extraPackages = with pkgs; optionals cfg.enableGamescope [
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
    });
}
