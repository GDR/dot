{ inputs, lib, pkgs, home-manager, options, config, overlays, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in
with lib; {
  options = with types; {
    user = mkOption {
      type = attrs;
    };

    home = {
      file = mkOption {
        type = attrs;
        default = { };
        description = "Files to place directly in $HOME";
      };
      configFile = mkOption {
        type = attrs;
        default = { };
        description = "Files to place in $XDG_CONFIG_HOME";
      };
      dataFile = mkOption {
        type = attrs;
        default = { };
        description = "Files to place in $XDG_DATA_HOME";
      };
      programs = mkOption {
        type = attrs;
        default = { };
        description = "Programs defined in home-manager";
      };
      packages = mkOption {
        type = attrs;
        default = [ ];
        description = "Packages defined in home-manager";
      };
      activation = mkOption {
        type = attrs;
        default = { };
        description = "Activation scripts";
      };
    };
  };
  config = {
    nixpkgs.overlays = [
      # (
      #   # final: prev: {
      #   #   apple-emoji-ttf = final.callPackage ../../pkgs/apple-emoji-ttf {};
      #   # }
      # )
      # overlays.additions
    ];

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;

      users.dgarifullin = {
        nixpkgs.config.allowUnfree = true;
        home = {
          stateVersion = "24.05";
          file = mkAliasDefinitions options.home.file;
        };
        xdg = {
          configFile = mkAliasDefinitions options.home.configFile;
          dataFile = mkAliasDefinitions options.home.dataFile;
        };

        programs = mkAliasDefinitions options.home.programs;
        home.packages = mkAliasDefinitions options.home.packages;
        home.activation = mkAliasDefinitions options.home.activation;
      };
    };
    users.users.dgarifullin = lib.mkMerge [
      {
        name = "dgarifullin";
        home = if isDarwin then "/Users/dgarifullin" else "/home/dgarifullin";
        uid = 1000;
      }
    ];

    nix.settings = let users = [ "root" "dgarifullin" ]; in {
      trusted-users = users;
      allowed-users = users;
    };
  };
}
