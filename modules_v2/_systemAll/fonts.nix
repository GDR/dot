# System-wide fonts - cross-platform
{ config, pkgs, lib, ... }: with lib;
let
  cfg = config.systemAll.fonts;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in
{
  options.systemAll.fonts = {
    enable = mkEnableOption "System-wide font packages";
  };

  config = mkIf cfg.enable {
    fonts.packages = with pkgs; [
      hack-font
      pixel-code
      nerd-fonts.fira-code
    ] ++ lib.optionals isLinux [
      # Apple emojis for Linux (already available on macOS)
      apple-emoji-ttf
    ];

    # Configure fontconfig to prioritize Apple Color Emoji over Noto Color Emoji
    fonts.fontconfig.defaultFonts.emoji = lib.optionals isLinux [
      "Apple Color Emoji"
      "Noto Color Emoji"
    ];

    # Additional fontconfig rules for better emoji fallback in applications like Cursor
    # This ensures Apple Color Emoji is preferred for emoji characters in mixed text
    fonts.fontconfig.localConf = lib.optionalString isLinux ''
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
