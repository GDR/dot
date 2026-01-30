# qBittorrent torrent client
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  tags = [ "downloads" ];
  platforms = [ "linux" "darwin" ];
  description = "qBittorrent torrent client";
  module = {
    allSystems.home.packages = [ pkgs.qbittorrent ];
  };
}
