{
    inputs = {
        nixpkgs = {
            url = "github:NixOS/nixpkgs/nixpkgs-unstable";
        };

        nix-darwin = {
            url = "github:LnL7/nix-darwin";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, ... }: let 
        lib = nixpkgs.lib.extend (lib: _: let hm = inputs.home-manager.lib.hm; in {
            inherit hm;
            my = import ./lib { inherit inputs lib; };
        });
    in {
        inherit lib;

        darwinConfigurations.mac-italy = nix-darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            specialArgs = { inherit self inputs lib; };
            modules = [ ./hosts/mac-italy ]
            ++ (import ./modules/common { inherit inputs lib; }).modules
            ++ (import ./modules/darwin { inherit inputs lib; }).modules;
        };
    };
}