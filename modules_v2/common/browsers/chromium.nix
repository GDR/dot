# Chromium browser
{ config, pkgs, lib, system, _modulePath, ... }: with lib;
let
  mkModule = lib.my.mkModule system;
  modulePath = _modulePath;
  moduleTags = [ "browsers" ];
  
  pathParts = splitString "." modulePath;
  cfg = foldl (acc: part: acc.${part}) config.modules pathParts;
  
  isDarwin = pkgs.stdenv.isDarwin;
  enabledUsers = filterAttrs (_: u: u.enable) config.hostUsers;
in
{
  meta = lib.my.mkModuleMeta {
    tags = moduleTags;
    description = "Chromium web browser";
  };

  options = lib.my.mkModuleOptions modulePath {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = let
    shouldEnable = lib.my.shouldEnableModule { inherit config modulePath moduleTags; };
  in mkIf shouldEnable (mkMerge [
    # Chromium program config (via mkModule alias system)
    (mkModule {
      darwinSystems.homebrew.casks = [ "chromium" ];
      nixosSystems.home.programs.chromium = {
        enable = true;
        commandLineArgs = [
          "--ignore-gpu-blocklist"
          "--enable-gpu-rasterization"
          "--enable-zero-copy"
          "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"
          "--enable-accelerated-video-decode"
          "--ozone-platform-hint=auto"
        ];
      };
    })
    
    # Desktop entry (direct to home-manager, not aliased)
    (mkIf (!isDarwin) {
      home-manager.users = mapAttrs (name: _: {
        xdg.desktopEntries.chromium = {
          name = "Chromium";
          genericName = "Web Browser";
          exec = "chromium %U";
          icon = "chromium";
          terminal = false;
          categories = [ "Network" "WebBrowser" ];
          mimeType = [ "text/html" "text/xml" "application/xhtml+xml" "x-scheme-handler/http" "x-scheme-handler/https" ];
        };
      }) enabledUsers;
    })
  ]);
}
