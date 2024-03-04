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
          };
          workstation = {
            fonts.enable = true;
            editor = {
              # vscode.enable = true;
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
        system.configurationRevision = self.rev or self.dirtyRev or null;

        security.pam.enableSudoTouchIdAuth = true;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 4;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";
      };

      lib = nixpkgs.lib.extend (lib: _: {
        my = import ./lib { inherit inputs lib; };
      });

      modules = import ./modules { inherit inputs lib; nixpkgs = nixpkgsConfig; };
    in
    rec
    {
      inherit lib modules;

      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#mac-italy
      darwinConfigurations.mac-italy = nix-darwin.lib.darwinSystem {
        modules = [ configuration ] ++ (modules.modules) ++ [
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."mac-italy".pkgs;
    };
}
