# Tailscale VPN - Linux system module
{ lib, pkgs, ... }@args:

lib.my.mkSystemModuleV2 args {
  namespace = "linux";
  description = "Tailscale VPN client and daemon";

  extraOptions = {
    routingMode = lib.mkOption {
      type = lib.types.enum [ "none" "client" "server" "both" ];
      default = "client";
      description = "Tailscale routing features mode.";
    };
  };

  module = cfg: {
    # Enable kernel IP forwarding only when acting as a subnet router / exit node
    boot.kernel.sysctl = lib.mkIf (lib.elem cfg.routingMode [ "server" "both" ]) {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    # Tailscale service
    services.tailscale = {
      enable = true;
      useRoutingFeatures = cfg.routingMode;
    };

    # after = ordering guarantee (tailscaled starts AFTER network is up)
    # wants = soft dependency (won't kill tailscaled if network-online fails)
    # requires alone doesn't enforce order — units can still start in parallel
    systemd.services.tailscaled = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };

    # Auto-reconnect on boot only when persisted auth state exists, bounded by timeout
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
        if [ -s /var/lib/tailscale/tailscaled.state ]; then
          ${pkgs.tailscale}/bin/tailscale up --timeout=10s || true
        fi
      '';
    };

    # Firewall settings
    networking.firewall.checkReversePath = "loose";
  };
}
