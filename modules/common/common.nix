{ inputs, lib, pkgs, home-manager, options, config, overlays, system, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in
with lib; {
  options = with types; {
    user = mkOption {
      type = attrs;
    };

    security-keys = mkOption {
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
      sessionVariables = mkOption {
        type = attrs;
        default = { };
        description = "Session variables";
      };
    };

    openssh = mkOption {
      type = attrs;
      default = { };
      description = "Packages defined in home-manager";
    };
  };
  config = {
    nixpkgs.overlays = [
      overlays.${system}.additions
      overlays.${system}.modifications
    ];

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;

      users.dgarifullin = {
        nixpkgs.config.allowUnfree = true;
        home = {
          stateVersion = "24.11";
          file = mkAliasDefinitions options.home.file;
        };
        xdg = {
          configFile = mkAliasDefinitions options.home.configFile;
          dataFile = mkAliasDefinitions options.home.dataFile;
        };

        programs = mkAliasDefinitions options.home.programs;
        home.packages = mkAliasDefinitions options.home.packages;
        home.activation = mkAliasDefinitions options.home.activation;
        home.sessionVariables = mkAliasDefinitions options.home.sessionVariables;
      };
    };

    users.users.dgarifullin = lib.mkMerge [
      {
        name = "dgarifullin";
        home = if isDarwin then "/Users/dgarifullin" else "/home/dgarifullin";
        uid = 1000;

        openssh = mkAliasDefinitions options.openssh;
      }
    ];

    nix.settings = let users = [ "root" "dgarifullin" ]; in {
      trusted-users = users;
      allowed-users = users;
    };
  };
}
