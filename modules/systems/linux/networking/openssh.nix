# OpenSSH server with charon-key AuthorizedKeysCommand
# Uses github:GDR/charon-key nixosModules.default for the wrapper + sshd config.
# This module enables openssh and passes userMap to services.charon-key.
{ lib, ... }@args:

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

  module = cfg: lib.mkMerge [
    {
      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = lib.mkDefault false;
          KbdInteractiveAuthentication = lib.mkDefault false;
          PermitRootLogin = lib.mkDefault "no";
        };
      };
    }
    (lib.mkIf (cfg.userMap != { }) {
      services.charon-key = {
        enable = true;
        userMap = lib.mapAttrs (_: ghUser: [ ghUser ]) cfg.userMap;
      };
    })
  ];
}
