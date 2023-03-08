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

    #Custom flakes
    nixpkgs-f2k.url = "github:fortuneteller2k/nixpkgs-f2k";
  };

  outputs = { self, nur, nixpkgs, home-manager, ... }@inputs:
  let
    inherit (self) outputs;
    forAllSystems = nixpkgs.lib.genAttrs [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
  in rec {
    lib = nixpkgs.lib.extend (lib: _: {
      my = import ./lib { inherit inputs lib; };
    });

    overlays = import ./overlays { inherit inputs lib; };

    modules = import ./modules { inherit inputs lib; };

    packages = forAllSystems (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in import ./pkgs { inherit pkgs; }
    );

    devShells = forAllSystems (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in import ./shell.nix { inherit pkgs; }
    );

    nixosConfigurations = {
      Nix-Germany = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs outputs lib; };
        modules = (modules.modules) ++ [
          ./hosts/nix-germany
        ];
      };
    };
  };
}
