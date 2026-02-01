# System-wide fonts - cross-platform
{ lib, pkgs, ... }@args:

lib.my.mkSystemModuleV2 args {
  namespace = "all";
  description = "System-wide font packages";

  # Linux gets font packages and fontconfig; Darwin uses system fonts
  moduleLinux = _: {
    fonts.packages = with pkgs; [
      hack-font
      pixel-code
      nerd-fonts.fira-code
      # Apple emojis for Linux (already available on macOS)
      apple-emoji-ttf
    ];

    # Configure fontconfig to prioritize Apple Color Emoji
    fonts.fontconfig.defaultFonts.emoji = [
      "Apple Color Emoji"
      "Noto Color Emoji"
    ];

    # Fontconfig rules for better emoji fallback in applications
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
