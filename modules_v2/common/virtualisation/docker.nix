# Docker container runtime
{ lib, pkgs, config, system, ... }@args: with lib;
let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  enabledUsers = filterAttrs (_: u: u.enable) (config.hostUsers or { });
  enabledUsernames = attrNames enabledUsers;

  baseModule = lib.my.mkModuleV2 args {
    tags = [ "oci-containers" ];
    platforms = [ "linux" "darwin" ];
    description = "Docker container runtime";
    module = {
      darwinSystems.home.packages = with pkgs; [
        docker
        docker-credential-helpers
      ];
    };
  };
in
baseModule // {
  config = mkMerge [
    baseModule.config
    # Linux: Enable docker daemon system-wide, add users to docker group
    (mkIf isLinux {
      virtualisation.docker.enable = true;

      # Add all enabled users to docker group
      users.users = listToAttrs (map
        (username: {
          name = username;
          value = { extraGroups = [ "docker" ]; };
        })
        enabledUsernames);
    })
  ];
}
