# Docker container runtime
{ lib, pkgs, config, ... }@args: with lib;
let
  enabledUsers = filterAttrs (_: u: u.enable) (config.hostUsers or { });
  enabledUsernames = attrNames enabledUsers;
in
lib.my.mkModuleV2 args {
  platforms = [ "linux" "darwin" ];
  description = "Docker container runtime";
  systemModule = {
    nixosSystems = {
      # Linux: Enable docker daemon system-wide, add users to docker group
      virtualisation.docker.enable = true;

      # Add all enabled users to docker group
      users.users = lib.my.mkUsersAttrs enabledUsernames (username: {
        extraGroups = [ "docker" ];
      });
    };
  };
  module = {
    darwinSystems.home.packages = with pkgs; [
      docker
      docker-credential-helpers
    ];
  };
}
