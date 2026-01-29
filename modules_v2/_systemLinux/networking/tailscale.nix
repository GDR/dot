# Tailscale VPN - Linux system module
{ config, pkgs, lib, ... }: with lib;

let
  cfg = config.systemLinux.networking.tailscale;
in
{
  options.systemLinux.networking.tailscale = {
    enable = mkEnableOption "Tailscale VPN client and daemon";
  };

  config = mkIf cfg.enable {
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

    # Systray app (for first enabled hostUser)
    home-manager.users = mapAttrs
      (name: _: {
        home.packages = [ pkgs.tailscale-systray ];
      })
      (filterAttrs (_: u: u.enable) config.hostUsers);
  };
}
