# Fontconfig settings for Linux (NixOS-specific)
# This extends systemAll.fonts with Linux-specific fontconfig configuration
{ config, lib, ... }: with lib;
let
  cfg = config.systemAll.fonts;
in
{
  config = mkIf cfg.enable {
    # Configure fontconfig to prioritize Apple Color Emoji over Noto Color Emoji
    fonts.fontconfig.defaultFonts.emoji = [
      "Apple Color Emoji"
      "Noto Color Emoji"
    ];

    # Additional fontconfig rules for better emoji fallback in applications like Cursor
    # This ensures Apple Color Emoji is preferred for emoji characters in mixed text
    fonts.fontconfig.localConf = ''
      <!-- Add Apple Color Emoji to fallback chain for all fonts -->
      <alias>
        <family>sans-serif</family>
        <prefer>
          <family>Apple Color Emoji</family>
        </prefer>
      </alias>
      <alias>
        <family>serif</family>
        <prefer>
          <family>Apple Color Emoji</family>
        </prefer>
      </alias>
      <alias>
        <family>monospace</family>
        <prefer>
          <family>Apple Color Emoji</family>
        </prefer>
      </alias>
    '';
  };
}

