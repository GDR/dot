{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.secure.wireguard;
in {
  options.modules.secure.wireguard = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    # boot.extraModulePackages = [ config.boot.kernelPackages.wireguard ];
    environment.systemPackages = [ pkgs.wireguard-tools ];

    networking.wireguard.enable = true;

    networking.firewall = {
      allowedUDPPorts = [ 51820 ]; # Clients and peers can use the same port, see listenport
    };

    networking.wg-quick.interfaces = {
      # wg0 = {
      #   address = [ "10.13.13.2/32" ];
      #   dns = [ "10.13.13.1" ];
      #   privateKeyFile = "/opt/wg/private_key";
      # };
    };
  };
}
