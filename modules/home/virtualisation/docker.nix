# Docker container runtime
{ lib, pkgs, config, _modulePath, ... }@args: with lib;

lib.my.mkModuleV2 args {
  platforms = [ "linux" "darwin" ];
  description = "Docker container runtime";
  systemModule = {
    nixosSystems = {
      # Linux: Enable docker daemon system-wide, add users to docker group
      virtualisation.docker.enable = true;

      # Add only users who enabled Docker to docker group
      users.users = lib.my.mkUsersAttrs { inherit config _modulePath; } (username: {
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
