# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{ inputs, lib, config, pkgs, ... }: {

  imports = [
    inputs.hardware.nixosModules.lenovo-thinkpad-t480

    ./hardware-configuration.nix

    ../_common/users/gdr.nix
    ../_common
  ];

  networking.hostName = "Nix-Germany";
}
