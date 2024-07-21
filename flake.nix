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
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, nix-homebrew, ... }:
    let
      lib = nixpkgs.lib.extend (lib: _:
        let hm = inputs.home-manager.lib.hm; in {
          inherit hm;
          my = import ./lib { inherit inputs lib; };
        });

      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      overlays = forAllSystems (system: import ./overlays { inherit inputs lib system; });

      mkDarwinConfiguration = host-config:
        let
          system = "aarch64-darwin";
        in
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit self inputs lib overlays system; };
          modules = [ host-config ]
            ++ (import ./modules/common { inherit inputs lib overlays; }).modules
            ++ (import ./modules/darwin { inherit inputs lib overlays; }).modules;
        };

      mkLinuxConfiguration = host-config:
        let
          system = "x86_64-linux";
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit self inputs lib overlays system; };
          modules = [ host-config ]
            ++ (import ./modules/common { inherit inputs lib overlays; }).modules
            ++ (import ./modules/darwin { inherit inputs lib overlays; }).modules;
        };
    in
    {
      inherit lib;

      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./pkgs { inherit pkgs lib system; }
      );

      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            buildInputs = [ pkgs.nixpkgs-fmt ];
          };
        }
      );

      darwinConfigurations.mac-italy = mkDarwinConfiguration ./hosts/mac-italy;
    };
}
