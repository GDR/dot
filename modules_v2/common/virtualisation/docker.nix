# Docker container runtime
{ config, pkgs, lib, system, _modulePath, ... }: with lib;
let
  modulePath = _modulePath;
  moduleTags = [ "oci-containers" ];

  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # Get users who have this module enabled via tag
  enabledUsers = lib.my.getUsersWithModule { inherit config modulePath moduleTags; };
  enabledUsernames = attrNames enabledUsers;
  hasEnabledUsers = enabledUsernames != [ ];
in
{
  meta = lib.my.mkModuleMeta {
    tags = moduleTags;
    platforms = [ "linux" "darwin" ];
    description = "Docker container runtime";
  };

  options = lib.my.mkModuleOptions modulePath {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config =
    let
      shouldEnable = lib.my.shouldEnableModule { inherit config modulePath moduleTags; };
    in
    mkIf shouldEnable (mkMerge [
      # Linux: Enable docker daemon system-wide, add users to docker group
      (mkIf isLinux {
        virtualisation.docker.enable = true;

        # Add all users with the tag to docker group
        users.users = listToAttrs (map
          (username: {
            name = username;
            value = { extraGroups = [ "docker" ]; };
          })
          enabledUsernames);
      })

      # Darwin: Install docker CLI packages for users
      (mkIf isDarwin {
        home-manager.users = mapAttrs
          (name: _: {
            home.packages = with pkgs; [
              docker
              docker-credential-helpers
            ];
          })
          enabledUsers;
      })
    ]);
}
