# Vivaldi browser - cross-platform with Chrome Web Store extensions support
# =============================================================================
# Uses home-manager's built-in programs.vivaldi module (part of chromium.nix)
#
# On Darwin: Uses homebrew cask (package = null), extensions via home-manager
# On Linux:  Uses nixpkgs vivaldi + extensions, dictionaries, CLI args
#
# Extensions are written to:
#   Darwin: ~/Library/Application Support/vivaldi/External Extensions/
#   Linux:  ~/.config/vivaldi/External Extensions/
#
# How to find extension IDs:
#   1. Install extension manually in Vivaldi
#   2. Go to vivaldi://extensions/
#   3. Enable "Developer mode" (top-right toggle)
#   4. Copy the ID from the extension card
#
# For local CRX extensions:
#   1. Download CRX from chrome.google.com/webstore/detail/<id>
#   2. Rename .crx to .zip, extract, read version from manifest.json
#   3. Use crxPath + version in extensions config
# =============================================================================
{ lib, pkgs, system, ... }@args:
lib.my.mkModuleV2 args {
  tags = [ "browsers" ];
  platforms = [ "linux" "darwin" ];
  description = "Vivaldi web browser with extensions";

  module = {
    # -------------------------------------------------------------------------
    # Shared: programs.vivaldi base config (extensions, dictionaries)
    # -------------------------------------------------------------------------
    allSystems = {
      programs.vivaldi = {
        enable = true;

        # Chrome Web Store extensions (work on both platforms)
        # Format: "id" or { id = "..."; } or { id = "..."; updateUrl = "..."; }
        # or { id = "..."; crxPath = "/path/to.crx"; version = "1.0"; }
        extensions = [
          # uBlock Origin - Best ad blocker
          # https://chromewebstore.google.com/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm
          { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }

          # Dark Reader - Dark mode for all websites
          # https://chromewebstore.google.com/detail/dark-reader/eimadpbcbfnmbkopoojfekhnkhdbieeh
          { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; }

          # Bitwarden - Password manager
          # https://chromewebstore.google.com/detail/bitwarden/nngceckbapebfimnlniiiahkandclblb
          { id = "nngceckbapebfimnlniiiahkandclblb"; }

          # Bypass Paywalls Clean - Custom update URL (GitHub-hosted)
          {
            id = "dcpihecpambacapedldabdbpakmachpb";
            updateUrl = "https://raw.githubusercontent.com/iamadamdev/bypass-paywalls-chrome/master/updates.xml";
          }

          # Example: Local CRX extension (uncomment and customize)
          # {
          #   id = "abcdefghijklmnopabcdefghijklmnop";
          #   crxPath = "/home/user/.local/share/extensions/my-extension.crx";
          #   version = "1.0.0";
          # }
        ];

        # Spell-check dictionaries
        dictionaries = [
          pkgs.hunspellDictsChromium.en_US
          # pkgs.hunspellDictsChromium.de_DE  # German
          # pkgs.hunspellDictsChromium.ru_RU  # Russian
        ];

        # Native messaging hosts for desktop integration
        # nativeMessagingHosts = [
        #   pkgs.browserpass  # Pass integration (cross-platform)
        # ];
      };
    };

    # -------------------------------------------------------------------------
    # Darwin: install via homebrew cask, package = null
    # -------------------------------------------------------------------------
    darwinSystems = {
      programs.vivaldi.package = null;  # Install via: brew install --cask vivaldi
      homebrew.casks = [ "vivaldi" ];
    };

    # -------------------------------------------------------------------------
    # Linux: nixpkgs package + performance flags + codecs
    # -------------------------------------------------------------------------
    nixosSystems = {
      programs.vivaldi.commandLineArgs = [
        "--ignore-gpu-blocklist"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"
        "--enable-accelerated-video-decode"
        "--ozone-platform-hint=auto"
        # "--enable-logging=stderr"  # Uncomment for debugging
      ];

      # Proprietary codecs (H.264, AAC) - separate package
      home.packages = [
        pkgs.vivaldi-ffmpeg-codecs
      ];

      # Desktop entry for application launchers
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
  };
}

