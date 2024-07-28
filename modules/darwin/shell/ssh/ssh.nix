{ config, options, pkgs, lib, ... }: with lib;
let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  cfg = config.modules.common.shell.ssh;

  # Fetch the authorized keys file
  authorizedKeysFile = pkgs.fetchurl {
    url = "https://github.com/gdr.keys";
    sha256 = "sha256:0zxxp8rww8a08adnvgda4cnxpfb1nl7sybx0i0cxdi7mhxdhkzbk";
  };
in
{
  options.modules.common.shell.ssh = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {

    openssh.authorizedKeys.keyFiles = [
      authorizedKeysFile
    ];
    home.file.".ssh/config".text = ''
      Host *
        AddKeysToAgent yes
        UseKeychain yes

      Host github.com
        User gdr
        IdentityFile ~/.ssh/mac_italy_id_rsa
    '';
  };
}
