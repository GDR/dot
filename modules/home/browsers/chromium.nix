# Chromium browser - cross-platform
# On Darwin, package = null means use externally installed Chromium (homebrew cask)
{ lib, pkgs, system, ... }@args:
let
  isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
in
lib.my.mkModuleV2 args {
  platforms = [ "linux" "darwin" ];
  description = "Chromium web browser";
  module = {
    # Darwin: manage config for externally-installed Chromium
    darwinSystems = {
      programs.chromium = {
        enable = true;
        package = null; # Install Chromium via: brew install --cask chromium
      };
    };
    # Linux: use nixpkgs chromium package
    nixosSystems = {
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
