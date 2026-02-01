# macOS system settings - Darwin-only system module
# Keyboard, trackpad, dock, finder, and other macOS preferences
{ config, lib, ... }:
let
  cfg = config.systemDarwin.macos-settings;
in
{
  options.systemDarwin.macos-settings = {
    enable = lib.mkEnableOption "macOS system settings (keyboard, trackpad, dock, finder)";
  };

  config = lib.mkIf cfg.enable {
    # Global settings
    system.defaults.NSGlobalDomain = {
      # Keyboard: fast key repeat
      InitialKeyRepeat = 15;
      KeyRepeat = 1;
      # Disable press and hold for accented characters (enables key repeat)
      ApplePressAndHoldEnabled = false;
      # Show all file extensions
      AppleShowAllExtensions = true;
      # Enable automatic dash substitution
      NSAutomaticDashSubstitutionEnabled = true;
    };

    # Dock settings
    system.defaults.dock = {
      autohide = false;
      orientation = "bottom";
      # Don't rearrange spaces based on most recent use
      mru-spaces = false;
      # Show indicator for hidden applications
      showhidden = true;
    };

    # Trackpad settings
    system.defaults.trackpad = {
      # Tap to click disabled (use physical click)
      Clicking = false;
      # Enable three finger drag
      TrackpadThreeFingerDrag = true;
    };

    # Finder settings
    system.defaults.finder = {
      # Show hidden files
      AppleShowAllFiles = true;
      # Show all file extensions
      AppleShowAllExtensions = true;
      # Show path bar at bottom
      ShowPathbar = true;
      # Show status bar at bottom
      ShowStatusBar = true;
    };

    # Screenshot settings
    system.defaults.screencapture = {
      # Save screenshots to Pictures/Screenshots
      location = "~/Pictures/Screenshots";
    };
  };
}

