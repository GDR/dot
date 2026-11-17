# OpenSSH server with charon-key AuthorizedKeysCommand (Darwin)
# Uses github:GDR/charon-key darwinModules.default for the wrapper + sshd config.
# This module enables Remote Login and passes userMap to services.charon-key on macOS.
{ lib, ... }@args:

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

  module =
    cfg:
    lib.mkMerge [
      {
        services.openssh = {
          enable = true;
          extraConfig = ''
            PasswordAuthentication no
            KbdInteractiveAuthentication no
            PermitRootLogin no
          '';
        };
      }
      (lib.mkIf (cfg.userMap != { }) {
        services.charon-key = {
          enable = true;
          userMap = lib.mapAttrs (_: ghUser: [ ghUser ]) cfg.userMap;
        };

        # Remove nix-darwin's default AuthorizedKeysCommand (101-authorized-keys.conf)
        # which sorts before charon-key's 50-charon-key.conf alphabetically (1 < 5).
        # SSH uses the first AuthorizedKeysCommand it encounters, so nix-darwin's
        # /bin/cat would shadow charon-key's wrapper.
        environment.etc."ssh/sshd_config.d/101-authorized-keys.conf".text = lib.mkForce "";
      })
    ];

  # charon-key darwinModule writes /etc/ssh drop-ins imperatively in postActivation;
  # remove them if darwin.openssh is disabled so key authorization is cleanly revoked.
  moduleDisabled = _: {
    system.activationScripts.postActivation.text = ''
      if [ -f /etc/ssh/sshd_config.d/50-charon-key.conf ] || [ -f /etc/ssh/charon-key-wrapper ]; then
        rm -f /etc/ssh/sshd_config.d/50-charon-key.conf /etc/ssh/charon-key-wrapper
        launchctl kickstart -k system/com.openssh.sshd 2>/dev/null || true
      fi
    '';
  };
}
