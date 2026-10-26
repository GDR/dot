# Vivaldi browser - cross-platform with Chrome Web Store extensions support
{ lib, ... }:

let
  sharedExtensions = [
    # uBlock Origin - Best ad blocker
    { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }

    # Dark Reader - Dark mode for all websites
    { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; }

    # Bitwarden - Password manager
    { id = "nngceckbapebfimnlniiiahkandclblb"; }

    # Bypass Paywalls Clean - Custom update URL (GitHub-hosted)
    {
      id = "dcpihecpambacapedldabdbpakmachpb";
      updateUrl = "https://raw.githubusercontent.com/iamadamdev/bypass-paywalls-chrome/master/updates.xml";
    }
  ];
in
lib.my.mkFeature {
  description = "Vivaldi web browser with extensions";

  darwinModule = {
    homebrew.casks = [ "vivaldi" ];
  };

  homeModuleDarwin = { ... }: {
    programs.vivaldi = {
      enable = true;
      package = null; # Install via: brew install --cask vivaldi
      extensions = sharedExtensions;
    };
  };

  homeModuleLinux = { pkgs, ... }: {
    programs.vivaldi = {
      enable = true;
      extensions = sharedExtensions;

      commandLineArgs = [
        "--ignore-gpu-blocklist"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder,UseHDRTransferFunction,WebRTCPipeWireCapturer"
        "--enable-accelerated-video-decode"
        "--ozone-platform-hint=auto"
        "--force-device-scale-factor=1.25"
        "--use-pulseaudio"
      ];

      dictionaries = [
        pkgs.hunspellDictsChromium.en_US
      ];
    };

    home.packages = [
      pkgs.vivaldi-ffmpeg-codecs
    ];

    xdg.desktopEntries.vivaldi = {
      name = "Vivaldi";
      genericName = "Web Browser";
      exec = "vivaldi %U";
      icon = "vivaldi";
      terminal = false;
      categories = [ "Network" "WebBrowser" ];
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
