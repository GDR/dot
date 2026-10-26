# VirtualBox virtualization
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "linux" "darwin" ];
  description = "VirtualBox virtualization";

  nixosModule = { selectedUsers, lib, ... }: {
    virtualisation.virtualbox.host.enable = true;

    users.users = lib.genAttrs selectedUsers (_: {
      extraGroups = [ "vboxusers" ];
    });
  };

  darwinModule = {
    homebrew.casks = [ "virtualbox" ];
  };

  homeModuleLinux = { pkgs, ... }: {
    home.packages = with pkgs; [
      virtualbox
    ];
  };
}
