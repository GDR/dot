{ inputs, config, options, lib, pkgs, ... }: with lib; {
  config = {
    # Global settings
    system.defaults.NSGlobalDomain = {
      # Set initial key repeat
      InitialKeyRepeat = 15;
      # Set key repeat
      KeyRepeat = 1;
      # Show all file extensions
      AppleShowAllExtensions = true;
      # Enable automatic dash substitution
      NSAutomaticDashSubstitutionEnabled = true;
      # Disable press and hold
      ApplePressAndHoldEnabled = false;
    };
    # Dock settings
    system.defaults.dock = {
      # Disable autohide
      autohide = false;
      # Set orientation to bottom
      orientation = "bottom";
      # Disable mru-spaces
      mru-spaces = false;
      # Show hidden files
      showhidden = true;
    };
    # Trackpad settings
    system.defaults.trackpad = {
      # Enable tap to click
      Clicking = false;

      # Enable three finger drag
      TrackpadThreeFingerDrag = true;
    };
    # Finder settings
    system.defaults.finder = {
      # Show all files
      AppleShowAllFiles = true;
      # Show all file extensions
      AppleShowAllExtensions = true;
      # Show path bar
      ShowPathbar = true;
      # Show status bar
      ShowStatusBar = true;
    };
    system.defaults.screencapture = {
      # Save screenshots to the desktop
      location = "~/Pictures/Screenshots";
    };
  };
}
