{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.virtualization.minikube;
in
{
  options.modules.virtualization.minikube = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      minikube
      kubernetes
      kubectl
      libvirt
      qemu
      virt-manager
    ];

    security.sudo.extraConfig = ''
      gdr ALL=(ALL) NOPASSWD: ${pkgs.podman}/bin/podman
    '';
  };
}
