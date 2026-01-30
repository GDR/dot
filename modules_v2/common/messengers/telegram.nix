# Telegram messenger
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  tags = [ "messengers" ];
  platforms = [ "linux" "darwin" ];
  description = "Telegram desktop messenger";
  module = {
    nixosSystems.home.packages = [ pkgs.telegram-desktop ];
    darwinSystems.homebrew.casks = [ "telegram" ];
  };
}
