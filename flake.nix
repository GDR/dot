{
  description = "Your new nix config";

  inputs = {
    # Hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable"; 

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = { nur, nixpkgs, home-manager, ... }@inputs:
    rec {
      overlays = import ./overlays;

      nixosModules = import ./modules/default.nix inputs;

      nixosConfigurations = {
        Nix-Germany = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = (nixosModules.modules) ++ [
            ./hosts/nix-germany
          ];
        };
      };
    };
}
