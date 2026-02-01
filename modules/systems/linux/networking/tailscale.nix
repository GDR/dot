# Tailscale VPN - Linux system module
{ lib, pkgs, config, ... }@args:

lib.my.mkSystemModuleV2 args {
  namespace = "linux";
  description = "Tailscale VPN client and daemon";

  module = _: {
    # Kernel settings for forwarding
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    # Tailscale service
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };

    # Firewall settings
    networking.firewall.checkReversePath = "loose";

    # Systray app (for all enabled hostUsers)
    home-manager.users = lib.mapAttrs
      (name: _: {
        home.packages = [ pkgs.tailscale-systray ];
      })
      (lib.filterAttrs (_: u: u.enable) config.hostUsers);
  };
}
