# OpenSSH server with charon-key AuthorizedKeysCommand (Darwin)
# Uses github:GDR/charon-key darwinModules.default for the wrapper + sshd config.
# This module passes userMap to services.charon-key on macOS.
#
# Note: config is accessed via direct attribute access (lazy) rather than
# mkSystemModuleV2's cfg parameter (uses foldl' which is strict and causes
# infinite recursion when the result shapes the module's config output).
{ lib, config, ... }@args:

let
  cfg = config.systemDarwin.openssh or { };
  userMap = cfg.userMap or { };
in
lib.my.mkSystemModuleV2 args {
  namespace = "darwin";
  description = "OpenSSH server with charon-key for authorized keys (Darwin)";

  extraOptions = {
    userMap = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''{ "dgarifullin" = "gdr"; }'';
      description = "Map macOS user names to GitHub usernames for charon-key";
    };
  };

  module = _: lib.mkIf (userMap != { }) {
    services.charon-key = {
      enable = true;
      userMap = lib.mapAttrs (_: ghUser: [ ghUser ]) userMap;
    };
  };
}
