# qBittorrent torrent client
{ lib, ... }:

lib.my.mkFeature {
  description = "qBittorrent torrent client";
  homeModule = { pkgs, ... }: {
    home.packages = [ pkgs.qbittorrent ];
  };
}
