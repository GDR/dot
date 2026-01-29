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
  };
}
