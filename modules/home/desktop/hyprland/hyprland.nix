# Hyprland Wayland compositor
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "linux" ];
  description = "Hyprland Wayland compositor";

  # System-level configuration (requires root)
  systemModule = {
    nixosSystems = {
      # Enable Wayland and Hyprland
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
      };

      # Display Manager for Wayland
      services.greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
            user = "greeter";
          };
        };
      };

      # Unlock gnome-keyring at login via PAM so tuigreet auto-unlocks it
      # using the user's login password — no separate keyring password prompt.
      security.pam.services.greetd.enableGnomeKeyring = true;

      # XDG portal for screen sharing and file dialogs
      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-hyprland
          xdg-desktop-portal-gtk
        ];
      };

      # Keyboard layout (for Wayland)
      services.xserver = {
        enable = lib.mkDefault false;
        xkb = {
          layout = "us,ru";
          variant = ",mac";
          options = "grp:alt_space_toggle";
        };
      };

      # Console keyboard layout
      console.keyMap = "us";

      # Fonts for Waybar and other UI elements
      fonts.packages = with pkgs; [
        font-awesome
        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
      ];
    };
  };

  module = {
    nixosSystems = {
      # Start gnome-keyring daemon as a user systemd service.
      # Provides the Secret Service D-Bus API that Electron apps use
      # to store credentials (VS Code, Antigravity IDE, Chrome, etc.).
      services.gnome-keyring = {
        enable = true;
        components = [ "secrets" "ssh" ];
      };

      # gcr provides the GUI unlock prompter (fallback if PAM didn't unlock)
      home.packages = [ pkgs.gcr ];
    };
  };

  # Dotfiles symlink (live-editable)
  dotfiles = {
    path = "hypr";
    source = "modules/home/desktop/hyprland/dotfiles";
  };
}
