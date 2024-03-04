{ pkgs, ... }: {
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    with pkgs; [
      nixpkgs-fmt
    ];

  modules = {
    common = {
      devtools = {
        direnv.enable = true;
        git.enable = true;
      };
      shell = {
        zsh.enable = true;
      };
      editors = {
        neovim.enable = true;
      };
      utils.enable = true;
    };
    workstation = {
      fonts.enable = true;
      editor = {
        vscode.enable = true;
      };
      terminal = {
        kitty.enable = true;
      };
      osx = {
        enable = true;
      };
    };
  };

  nix.configureBuildUsers = true;

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Create /etc/zshrc that loads the nix-darwin environment.
  # programs.zsh.enable = true; # default shell on catalina
  # programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  # system.configurationRevision = inputs.rev or inputs.dirtyRev or null;

  security.pam.enableSudoTouchIdAuth = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
