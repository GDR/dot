# Hyprland Wayland compositor - Linux system module
{ config, pkgs, lib, self, ... }: with lib;
let
  cfg = config.systemLinux.desktop.hyprland;
  enabledUsers = filterAttrs (_: u: u.enable) config.hostUsers;
in
{
  options.systemLinux.desktop.hyprland = {
    enable = mkEnableOption "Hyprland Wayland compositor";
  };

  config = mkIf cfg.enable {
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
      enable = mkDefault false;
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

    # User packages and dotfiles
    home-manager.users = mapAttrs
      (username: _: {
        home.packages = with pkgs; [
          # Application launcher
          rofi

          # Screenshot utilities
          grim
          slurp
          wl-clipboard

          # Audio control
          pamixer
          pavucontrol

          # Brightness control
          brightnessctl

          # Notification daemon
          dunst

          # Wallpaper
          swww

          # Status bar
          waybar

          # Terminal
          kitty

          # Network management
          networkmanagerapplet

          # macOS-style cursor theme
          whitesur-cursors

          # Cursor utilities
          dconf
        ];

        # Dotfiles symlink (live-editable)
        xdg.configFile."hypr".source =
          config.lib.file.mkOutOfStoreSymlink
            "${self.outPath}/modules_v2/_systemLinux/desktop/hyprland/dotfiles";
      })
      enabledUsers;
  };
}
