# VirtualBox virtualization
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "linux" "darwin" ];
  description = "VirtualBox virtualization";

  nixosModule = { selectedUsers, lib, ... }: {
    # Linux: Enable VirtualBox host, add users to vboxusers group
    virtualisation.virtualbox.host.enable = true;

    # Add only users who enabled VirtualBox to vboxusers group
    users.users = lib.genAttrs selectedUsers (_: {
      extraGroups = [ "vboxusers" ];
    });
  };

  # Darwin: pkgs.virtualbox in nixpkgs is x86_64-linux only (requires Oracle signed macOS kext/DriverKit installer)
  darwinModule = {
    homebrew.casks = [ "virtualbox" ];
  };

  homeModuleLinux = { pkgs, ... }: {
    home.packages = with pkgs; [
      virtualbox
    ];
  };
}
