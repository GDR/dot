# Chromium browser - cross-platform
# On Darwin, package = null means use externally installed Chromium (homebrew cask)
{ lib, ... }:

lib.my.mkFeature {
  description = "Chromium web browser";
  homeModuleDarwin = { ... }: {
    programs.chromium = {
      enable = true;
      package = null; # Install Chromium via: brew install --cask chromium
    };
  };
  homeModuleLinux = { ... }: {
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
}
