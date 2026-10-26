# Telegram messenger
{ lib, ... }:

lib.my.mkFeature {
  description = "Telegram desktop messenger";
  homeModule = { pkgs, ... }: {
    home.packages = [ pkgs.telegram-desktop ];
  };
}
