# VirtualBox virtualization
{ lib, pkgs, config, ... }@args: with lib;
let
  enabledUsers = filterAttrs (_: u: u.enable) (config.hostUsers or { });
  enabledUsernames = attrNames enabledUsers;
in
lib.my.mkModuleV2 args {
  platforms = [ "linux" "darwin" ];
  description = "VirtualBox virtualization";
  systemModule = {
    nixosSystems = {
      # Linux: Enable VirtualBox host, add users to vboxusers group
      virtualisation.virtualbox.host.enable = true;

      # Add all enabled users to vboxusers group
      users.users = lib.my.mkUsersAttrs enabledUsernames (username: {
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
