{
  description = "Example Darwin system flake";

  inputs = {
    # Basic url
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Darwin
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
    let
      inherit (nix-darwin.lib) darwinSystem;
      inherit (inputs.nixpkgs.lib) attrValues makeOverridable optionalAttrs singleton;

      nixpkgsConfig = {
        config = { allowUnfree = true; };
      };
      configuration = { pkgs, ... }: {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        environment.systemPackages =
          with pkgs; [
            nixpkgs-fmt
          ];


        nix.configureBuildUsers = true;

        # Auto upgrade nix package and the daemon service.
        services.nix-daemon.enable = true;
        # nix.package = pkgs.nix;

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";

        # Create /etc/zshrc that loads the nix-darwin environment.
        programs.zsh.enable = true; # default shell on catalina
        # programs.fish.enable = true;

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        security.pam.enableSudoTouchIdAuth = true;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 4;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#mac-italy
      darwinConfigurations."mac-italy" = nix-darwin.lib.darwinSystem {
        modules = [ configuration ] ++ [
          home-manager.darwinModules.home-manager
          {
            nixpkgs = nixpkgsConfig;

            users = {
              users = {
                gdr = {
                  shell = nixpkgs.zsh;
                  description = "Damir Garifullin";
                  home = "/Users/gdr";
                };
              };
            };
            # `home-manager` config
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.gdr = { pkgs, ... }: {
              home.stateVersion = "23.11";

              programs.zsh = {
                enable = true;
                enableCompletion = true;
                enableAutosuggestions = true;

                shellAliases = {
                  ls = "ls -l";
                  lsa = "ls -la";
                };
              };

              programs.git = {
                enable = true;
                userName = "Damir Garifullin";
                userEmail = "gosugdr@gmail.com";
              };

              programs.neovim = {
                enable = true;
                defaultEditor = true;
              };

              programs.vscode = {
                enable = true;
                extensions = with pkgs.vscode-extensions; [
                  ms-python.python
                  bbenoist.nix
                  jnoortheen.nix-ide
                ];
              };
            };
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."mac-italy".pkgs;
    };
}
