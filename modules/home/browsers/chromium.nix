# Chromium browser - cross-platform
# On Darwin, package = null means use externally installed Chromium (homebrew cask)
{ lib, ... }:

lib.my.mkFeature {
  description = "Chromium web browser";
  darwinModule =
    { config, lib, ... }:
    lib.mkIf (config.homebrew.enable or false) {
      # Upstream `chromium` cask was disabled on 2026-09-01 due to Gatekeeper checks;
      # `ungoogled-chromium` installs Chromium.app and remains active.
      homebrew.casks = [ "ungoogled-chromium" ];
    };
  homeModuleDarwin = _: {
    programs.chromium = {
      enable = true;
      package = null; # Installed via homebrew cask `ungoogled-chromium`
    };
  };
  homeModuleLinux = _: {
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
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeType = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
    };
  };
}
