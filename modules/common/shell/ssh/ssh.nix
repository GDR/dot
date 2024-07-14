{ config, options, pkgs, lib, ... }: with lib;
let 
    isDarwin = pkgs.stdenv.isDarwin;
    isLinux = pkgs.stdenv.isLinux;
    cfg = config.modules.common.shell.ssh; 

    # Hack to bypass fetchurl hash computation
    authorizedKeysFetcher = ''
        mkdir -p $HOME/.ssh
        ${pkgs.curl}/bin/curl -o $HOME/.ssh/authorized_keys https://github.com/gdr.keys > /dev/null 2>&1
    '';
in {
  options.modules.common.shell.ssh = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {

  } // mkIf pkgs.stdenv.isDarwin {
    users.users.dgarifullin.openssh = {
        authorizedKeys.keyFiles = [ "${pkgs.fetchurl { url = "https://github.com/gdr.keys"; }}" ];
    };
    home.activation = {
        sshActivation = authorizedKeysFetcher;
    };
  };
}