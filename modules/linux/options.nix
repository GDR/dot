{ config, options, inputs, lib, nixpkgs, home-manager, ... }:
with lib;
{
  imports = [
    # inputs.home-manager.darwinModules.home-manager
    # TODO make compatible with nixosModules
    inputs.home-manager.nixosModules.home-manager
  ];

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
    };
  };

  config =
    let
      user =
        let
          user = builtins.getEnv "USER";
          name = if elem user [ "" "root" ] then "gdr" else user;
        in
        {
          inherit name;
          isNormalUser = true;
          home = "/home/${name}";
          group = "users";
          extraGroups = [ "wheel" "audio" ];
          uid = 1000;
        };
    in
    {
      nixpkgs.config.allowUnfree = true;

      home-manager = {
        useUserPackages = true;
        useGlobalPkgs = true;

        users.${user.name} = {
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
        };
      };

      users.users.${user.name} = user;

      nix.settings = let users = [ "root" user.name ]; in {
        trusted-users = users;
        allowed-users = users;
      };
    };
}
