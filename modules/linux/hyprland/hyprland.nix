{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.linux.hyprland;
in
{
  options.modules.linux.hyprland = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
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

    # Essential Wayland packages
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

    # Also set console keyboard layout
    console.keyMap = "us";

    # Audio
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Fonts for Waybar and other UI elements
    fonts.packages = with pkgs; [
      font-awesome
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
    ];

    # Add Hyprland config files
    home.file.".config/hypr" = {
      source = ./dotfiles;
      force = true;  # Allow overwriting existing file/directory
    };
  };
}
