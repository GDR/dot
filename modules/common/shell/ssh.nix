{ config, options, pkgs, lib, system, ... }: with lib;
let
  isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
  isLinux = system == "aarch64-linux" || system == "x86_64-linux";
  cfg = config.modules.common.shell.ssh;
  mkModule = (conf: if isLinux then conf.common // conf.linux else conf.common // conf.darwin);

  # Fetch the authorized keys file
  authorizedKeysFile = pkgs.fetchurl {
    url = "https://github.com/gdr.keys";
    sha256 = "sha256-VUm1uR2PWacLZFqw5XkzSg/R0TlIXHV4zJTs5gg5yIs=";
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
      home.programs.ssh = {
        enable = true;
        matchBlocks = {
          "*" = {
            # addKeysToAgent = "yes";
            # useKeychain = "yes";
          };
          "github.com" = {
            user = "gdr";
            identityFile = "~/.ssh/germany_id_rsa";
          };
        };
        extraConfig = ''
          AddKeysToAgent yes
          UseKeychain yes
        '';
      };
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
    };
    darwin = { };
  });
}
