{ config, options, pkgs, lib, system, ... }: with lib;
let
  cfg = config.modules.common.virtualisation.kubernetes;
  mkModule = lib.my.mkModule system;
in
{
  options.modules.common.virtualisation.kubernetes = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable (mkModule {
    common = {
      home.packages = with pkgs; [
        kubectl
        kubectx
      ];
    };
    linux =
      let
        kubeMasterIP = "10.0.10.61";
        kubeMasterHostname = "api.kube";
        kubeMasterAPIServerPort = 6443;
      in
      {
        home.packages = with pkgs; [
          kubectl
          kubectx
          kompose
          kubernetes
        ];

        services.kubernetes = {
          roles = [ "master" "node" ];
          masterAddress = kubeMasterHostname;
          apiserverAddress = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
          easyCerts = true;
          apiserver = {
            securePort = kubeMasterAPIServerPort;
            advertiseAddress = kubeMasterIP;
          };

          # use coredns
          addons.dns.enable = true;

          # needed if you use swap
          kubelet.extraOpts = "--fail-swap-on=false";
        };
      };
  });
}
