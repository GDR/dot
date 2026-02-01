# NetworkManager - Linux system module
{ lib, ... }@args:

lib.my.mkSystemModuleV2 args {
  namespace = "linux";
  description = "NetworkManager for network configuration";

  module = _: {
    networking.networkmanager.enable = true;
    programs.nm-applet.enable = true;
  };
}
