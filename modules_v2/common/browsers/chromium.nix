# Chromium browser
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  tags = [ "browsers" ];
  description = "Chromium web browser";
  module = {
    allSystems = {
      programs.chromium = {
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
      xdg.desktopEntries.chromium = {
        name = "Chromium";
        genericName = "Web Browser";
        exec = "chromium %U";
        icon = "chromium";
        terminal = false;
        categories = [ "Network" "WebBrowser" ];
        mimeType = [ "text/html" "text/xml" "application/xhtml+xml" "x-scheme-handler/http" "x-scheme-handler/https" ];
      };
    };
  };
}
