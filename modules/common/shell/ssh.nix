{ config, options, pkgs, lib, system, ... }: with lib;
let
  isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
  isLinux = system == "aarch64-linux" || system == "x86_64-linux";
  cfg = config.modules.common.shell.ssh;
  mkModule = (conf: if isLinux then conf.common // conf.linux else conf.common // conf.darwin);

  # Fetch the authorized keys file
  authorizedKeysFile = pkgs.fetchurl {
    url = "https://github.com/gdr.keys";
    sha256 = "sha256:VUm1uR2PWacLZFqw5XkzSg/R0TlIXHV4zJTs5gg5yIs=";
  };
in
{
  options.modules.common.shell.ssh = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable (mkModule {
    common = {
      openssh.authorizedKeys.keyFiles = [
        authorizedKeysFile
      ];
    };
    linux = {
      services.openssh = {
        enable = true;
        permitRootLogin = "no";
        passwordAuthentication = false;
        extraConfig = ''
          AllowUsers dgarifullin
        '';
      };
      home.programs.ssh = {
        enable = true;
      };
    };
    darwin = {
      home.file.".ssh/config".text = ''
        Host *
          AddKeysToAgent yes
          UseKeychain yes

        Host github.com
          User gdr
          IdentityFile ~/.ssh/mac_italy_id_rsa
      '';
    };
  });
}
