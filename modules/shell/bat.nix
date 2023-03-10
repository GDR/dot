{ config, options, pkgs, lib, ... }:
lib.my.mkModule config ["shell" "bat"] {
  config = {
    user.packages = with pkgs; [ 
      bat 
    ];
  };
}
