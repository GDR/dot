# VirtualBox virtualization
{ lib, pkgs, config, _modulePath, ... }@args: with lib;

lib.my.mkModuleV2 args {
  platforms = [ "linux" "darwin" ];
  description = "VirtualBox virtualization";
  systemModule = {
    nixosSystems = {
      # Linux: Enable VirtualBox host, add users to vboxusers group
      virtualisation.virtualbox.host.enable = true;

      # Add only users who enabled VirtualBox to vboxusers group
      users.users = lib.my.mkUsersAttrs { inherit config _modulePath; } (username: {
        extraGroups = [ "vboxusers" ];
      });
    };
  };
  module = {
    nixosSystems.home.packages = with pkgs; [
      virtualbox
    ];
    darwinSystems.homebrew.casks = [ "virtualbox" ];
  };
}
