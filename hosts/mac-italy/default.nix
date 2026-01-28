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
        ghostty.enable = true;
        kitty.enable = true;
      };
      utils = {
        java.enable = true;
        keepassxc.enable = true;
        qbittorrent.enable = true;
        ollama.enable = true;
        wireguard.enable = true;
        yandex-cloud.enable = true;
      };
      messenger = {
        telegram.enable = true;
      };
      browsers = {
        chrome.enable = true;
      };
      virtualisation = {
        colima.enable = true;
        podman.enable = true;
        docker.enable = true;
      };
      media = {
        vlc.enable = true;
        spotify.enable = true;
      };
      vpn = {
        tailscale.enable = true;
      };
    };
    darwin = {
      utils = {
        chatgpt.enable = true;
        macfuse.enable = true;
        # obsidian.enable = true;
        raycast.enable = true;
        yaak.enable = true;
      };
      vpn = {
        outline-client.enable = true;
        outline-manager.enable = true;
      };
      ide = {
        xcode.enable = true;
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

  nix.enable = true;

  nix.settings.experimental-features = "nix-command flakes";

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = 4;

  nixpkgs.hostPlatform = "aarch64-darwin";

  nixpkgs.config.allowUnfree = true;

  security.pam.services.sudo_local.touchIdAuth = true;

  security-keys.signingkey = "/Users/dgarifullin/.ssh/mac_italy_id_rsa";

  home.programs.git.extraConfig.user = {
    signingkey = "/Users/dgarifullin/.ssh/mac_italy_id_rsa.pub";
  };
}
