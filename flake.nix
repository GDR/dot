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
        lib = nixpkgs.lib.extend (lib: _: {
            my = import ./lib { inherit inputs lib; };
        });
    in {
        darwinConfigurations.mac-italy = nix-darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            specialArgs = { inherit self inputs; };
            modules = [
                ./hosts/mac-italy
            ] ++ (import ./modules/common { inherit inputs lib; }).modules;
        };
    };
}