{ self, ... }: {
    modules = {
        common = {
            shell = {
                zsh.enable = true;
                git.enable = true;
                tmux.enable = true;
                utils.enable = true;
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
            terminal = {
                # iterm2.enable = true;
            };
            fonts.enable = true;
        };
    };

    services.nix-daemon.enable = true;

    nix.settings.experimental-features = "nix-command flakes";

    system.configurationRevision = self.rev or self.dirtyRev or null;

    system.stateVersion = 4;

    nixpkgs.hostPlatform = "aarch64-darwin";
    nixpkgs.config.allowUnfree = true;

    security.pam.enableSudoTouchIdAuth = true;
}