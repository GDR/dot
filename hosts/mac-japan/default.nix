{ self, pkgs, lib, overlays, ... }: {
  modules = {
    common = {
      shell = {
        git.enable = true;
        ssh.enable = true;
        tmux.enable = true;
        utils.enable = true;
        zsh.enable = true;
      };
      editors = {
        neovim.enable = true;
        vscode.enable = true;
      };
      terminal = {
        kitty.enable = true;
      };
      utils = {
        bazel.enable = true;
        java.enable = true;
        scala.enable = true;
        keepassxc.enable = true;
      };
      messenger = {
        telegram.enable = true;
      };
      browsers = {
        chrome.enable = true;
        firefox.enable = true;
      };
      virtualisation = {
        podman.enable = true;
        docker.enable = true;
      };
      media = {
        vlc.enable = true;
        spotify.enable = true;
      };
    };
    darwin = {
      utils = {
        chatgpt.enable = true;
        colima.enable = true;
        macfuse.enable = true;
        # obsidian.enable = true;
        yaak.enable = true;
      };
      vpn = {
        outline-client.enable = true;
        outline-manager.enable = true;
      };
      ide = {
        #        xcode.enable = true;
      };
    };
    fonts.enable = true;
  };

  nix.enable = true;

  nix.settings.experimental-features = "nix-command flakes";

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = 5;

  nixpkgs.hostPlatform = "aarch64-darwin";

  nixpkgs.config.allowUnfree = true;

  security.pam.services.sudo_local.touchIdAuth = true;

  security-keys.signingkey = "/Users/dgarifullin/.ssh/mac_japan_id_rsa";

  home.programs.git.extraConfig.user = {
    signingkey = "/Users/dgarifullin/.ssh/mac_japan_id_rsa.pub";
  };

  environment.variables = {
    TERM = "xterm-256color";
  };
  environment.etc = {
    "resolver/consul" = {
      text = ''
        nameserver 2a02:6b8:2:d::3f1
        port 53
      '';
    };
  };

  system.activationScripts.extraUserActivation.text = ''
    if [ ! -d /etc/resolver ]; then
      sudo mkdir -p /etc/resolver
      sudo chmod 755 /etc/resolver
    fi
  '';
}
