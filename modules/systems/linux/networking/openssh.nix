# OpenSSH server with charon-key AuthorizedKeysCommand
# Uses github:GDR/charon-key nixosModules.default for the wrapper + sshd config.
# This module enables openssh and passes userMap to services.charon-key.
#
# Note: config is accessed via direct attribute access (lazy) rather than
# mkSystemModuleV2's cfg parameter (uses foldl' which is strict and causes
# infinite recursion when the result shapes the module's config output).
{ lib, config, ... }@args:

let
  cfg = config.systemLinux.networking.openssh or { };
  userMap = cfg.userMap or { };
in
lib.my.mkSystemModuleV2 args {
  namespace = "linux";
  description = "OpenSSH server with charon-key for authorized keys";

  extraOptions = {
    userMap = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''{ "dgarifullin" = "gdr"; }'';
      description = "Map NixOS user names to GitHub usernames for charon-key";
    };
  };

  module = _: lib.mkMerge [
    { services.openssh.enable = true; }
    (lib.mkIf (userMap != { }) {
      services.charon-key = {
        enable = true;
        userMap = lib.mapAttrs (_: ghUser: [ ghUser ]) userMap;
      };
    })
  ];
}
