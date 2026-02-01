# System-wide fonts - cross-platform
{ lib, pkgs, ... }@args:

lib.my.mkSystemModuleV2 args {
  namespace = "all";
  description = "System-wide font packages";

  # Linux gets font packages; Darwin uses system fonts or homebrew
  moduleLinux = _: {
    fonts.packages = with pkgs; [
      hack-font
      pixel-code
      nerd-fonts.fira-code
      # Apple emojis for Linux (already available on macOS)
      apple-emoji-ttf
    ];
  };
}
