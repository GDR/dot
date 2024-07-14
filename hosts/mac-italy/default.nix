{ self, pkgs, lib,... }: {
    modules = {
        common = {
            shell = {
                zsh.enable = true;
                git.enable = true;
                tmux.enable = true;
                utils.enable = true;
                ssh.enable = true;
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
            };
        };
        darwin = {
            utils = {
                raycast.enable = true;
                yaak.enable = true;
            };
            vpn = {
                outline-client.enable = true;
                outline-manager.enable = true;  
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
    nixpkgs.config.allowUnsupportedSystem = true;
    nixpkgs.config.allowBroken = true;

    security.pam.enableSudoTouchIdAuth = true;
}