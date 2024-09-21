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
        keepassxc.enable = true;
        qbittorrent.enable = true;
        ollama.enable = true;
      };
      messenger = {
        telegram.enable = true;
      };
      browsers = {
        chrome.enable = true;
      };
      virtualisation = {
        podman.enable = true;
        docker.enable = true;
        kubernetes.enable = true;
      };
      media = {
        vlc.enable = true;
        spotify.enable = true;
      };
    };
    darwin = {
      utils = {
        chatgpt.enable = true;
        macfuse.enable = true;
        raycast.enable = true;
        yaak.enable = true;
      };
      vpn = {
        outline-client.enable = true;
        outline-manager.enable = true;
      };
      ui = {
        sketchybar.enable = true;
      };
      media = {
        iina.enable = true;
      };
    };
    fonts.enable = true;
  };

  services.nix-daemon.enable = true;

  nix.settings.experimental-features = "nix-command flakes";

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = 4;

  nixpkgs.hostPlatform = "aarch64-darwin";

  nixpkgs.config.allowUnfree = true;

  security.pam.enableSudoTouchIdAuth = true;

  security-keys.signingkey = "/Users/dgarifullin/.ssh/mac_italy_id_rsa";

  home.programs.git.extraConfig.user = {
    signingkey = "/Users/dgarifullin/.ssh/mac_italy_id_rsa.pub";
  };
}
