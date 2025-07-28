{ config, options, pkgs, lib, system, ... }: with lib;
let
  cfg = config.modules.common.vpn.tailscale;
  mkModule = lib.my.mkModule system;
in
{
  options.modules.common.vpn.tailscale = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable (mkModule {
    linux = {
      # Allow forwarding
      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1; # IPv4 forwarding
        "net.ipv6.conf.all.forwarding" = 1; # IPv6 forwarding
      };
      services.tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };

      networking.firewall.checkReversePath = "loose";

      home.packages = with pkgs; [
        tailscale-systray
      ];
    };
    darwin = {
      homebrew = {
        casks = [
          "tailscale"
        ];
      };
    };
  });
}
