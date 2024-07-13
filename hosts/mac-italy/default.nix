{ self, ... }: {
    modules = {
        common = {
            shell = {
                zsh.enable = true;
                utils.enable = true;
                git.enable = true;
                tmux.enable = true;
            };
            editors = {
                neovim.enable = true;
            };
            terminal = {
                kitty.enable = true;
            };
        };
        darwin = {
            utils = {
                raycast.enable = true;
            };
            vpn = {
                outline-client.enable = true;
                outline-manager.enable = true;
            };
        };
    };

    services.nix-daemon.enable = true;

    nix.settings.experimental-features = "nix-command flakes";

    system.configurationRevision = self.rev or self.dirtyRev or null;

    system.stateVersion = 4;

    nixpkgs.hostPlatform = "aarch64-darwin";

    security.pam.enableSudoTouchIdAuth = true;
}