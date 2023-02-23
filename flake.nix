{
  description = "My personal nixos configuration";

  inputs = {
    # Hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Hardware
    hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = { nur, nixpkgs, home-manager, ... }@inputs:
  rec {
    lib = nixpkgs.lib.extend (lib: _: {
      my = import ./lib { inherit inputs lib; };
    });

    overlays = import ./overlays;

    modules = import ./modules { inherit inputs lib; };

    nixosConfigurations = {
      Nix-Germany = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs lib; };
        modules = (modules.modules) ++ [
          ./hosts/nix-germany
        ];
      };
    };
  };
}
