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

  config = mkIf cfg.enable (mkMerge [
    # NixOS font packages (Linux only)
    (mkIf isLinux {
      fonts.packages = with pkgs; [
        hack-font
        pixel-code
        nerd-fonts.fira-code
        # Apple emojis for Linux (already available on macOS)
        apple-emoji-ttf
      ];
    })
    # On Darwin, fonts are typically installed via homebrew or are already available
    # No system-wide font installation needed
  ]);
}
