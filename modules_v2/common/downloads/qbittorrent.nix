# qBittorrent torrent client
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  tags = [ "downloads" ];
  platforms = [ "linux" "darwin" ];
  description = "qBittorrent torrent client";
  module = {
    nixosSystems.home.packages = [ pkgs.qbittorrent ];
    darwinSystems.homebrew.casks = [ "qbittorrent" ];
  };
}
