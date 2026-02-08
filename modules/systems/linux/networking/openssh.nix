# OpenSSH server with charon-key AuthorizedKeysCommand
# Uses github:GDR/charon-key for dynamic authorized keys (see INTEGRATION_EXAMPLES.md)
{ lib, system, inputs, config, ... }@args:

let
  charonKey = (inputs.charon-key or { }).packages.${system}.default or null;
  cfg = config.systemLinux.networking.openssh or { };
  userMap = cfg.userMap or { };
  userMapStr = lib.concatStringsSep "," (lib.mapAttrsToList (u: id: "${u}:${id}") userMap);
  authorizedKeysCommand =
    if charonKey != null then
      "${charonKey}/bin/charon-key" + lib.optionalString (userMap != { }) " --user-map ${userMapStr}"
    else null;
in
lib.my.mkSystemModuleV2 args {
  namespace = "linux";
  description = "OpenSSH server with charon-key for authorized keys";

  extraOptions = {
    userMap = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''{ "dgarifullin" = "gdr"; }'';
      description = "Map NixOS user names to charon-key identities (--user-map)";
    };
  };

  module = _: {
    services.openssh = {
      enable = true;
    }
    // lib.optionalAttrs (authorizedKeysCommand != null) {
      authorizedKeysCommand = authorizedKeysCommand;
      authorizedKeysCommandUser = "root";
    };
  };
}
