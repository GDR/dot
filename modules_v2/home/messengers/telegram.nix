# Telegram messenger
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  tags = [ "messengers" ];
  platforms = [ "linux" "darwin" ];
  description = "Telegram desktop messenger";
  module = {
    allSystems.home.packages = [ pkgs.telegram-desktop ];
  };
}
