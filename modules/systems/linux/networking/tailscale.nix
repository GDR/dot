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

    # after = ordering guarantee (tailscaled starts AFTER network is up)
    # wants = soft dependency (won't kill tailscaled if network-online fails)
    # requires alone doesn't enforce order — units can still start in parallel
    systemd.services.tailscaled = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };

    # Auto-reconnect on boot using persisted auth state in /var/lib/tailscale
    systemd.services.tailscale-autoconnect = {
      description = "Tailscale auto-connect on boot";
      after = [ "network-online.target" "tailscaled.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${pkgs.tailscale}/bin/tailscale up
      '';
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
