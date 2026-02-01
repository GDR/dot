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

  # Dotfiles symlink (live-editable)
  dotfiles = {
    path = "hypr";
    source = "modules/home/desktop/hyprland/dotfiles";
  };
}
