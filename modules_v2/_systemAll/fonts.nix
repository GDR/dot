# System-wide fonts - cross-platform
{ config, pkgs, lib, ... }: with lib;
let
  cfg = config.systemAll.fonts;
  isDarwin = pkgs.stdenv.isDarwin;
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
    ];
  };
}
