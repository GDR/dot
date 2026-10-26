# Docker container runtime
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "linux" "darwin" ];
  description = "Docker container runtime";

  nixosModule = { selectedUsers, lib, ... }: {
    virtualisation.docker.enable = true;

    users.users = lib.genAttrs selectedUsers (_: {
      extraGroups = [ "docker" ];
    });
  };

  homeModuleDarwin = { pkgs, ... }: {
    home.packages = with pkgs; [
      colima
      docker
      docker-credential-helpers
    ];
  };
}
