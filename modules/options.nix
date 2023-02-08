{ config, options, lib, nixpkgs, ...}:
with lib;
{
  options = with types; {
    user = mkOption {
      type = attrs;
    };

    home = {
      file = mkOption {
        type = attrs;
        default = {};
        description = "Files to place directly in $HOME";
      };
      configFile = mkOption {
        type = attrs;
        default = {};
        description = "Files to place in $XDG_CONFIG_HOME";
      };
      dataFile = mkOption {
        type = attrs;
        default = {};
        description = "Files to place in $XDG_DATA_HOME";
      };
      programs = mkOption {
        type = attrs;
        default = {};
        description = "Programs defined in home-manager";
      };
    };
  };

  config = {
    nixpkgs.config.allowUnfree = true;

    user =
      let user = builtins.getEnv "USER";
          name = if elem user [ "" "root" ] then "gdr" else user;
      in {
        inherit name;
        extraGroups = [ "wheel" ];
        isNormalUser = true;
        home = "/home/${name}";
        group = "users";
        uid = 1000;
      };

    home-manager = {
      useUserPackages = true;

      users.${config.user.name} = {
        nixpkgs.config.allowUnfree = true;
        home = {
          file = mkAliasDefinitions options.home.file;
          stateVersion = config.system.stateVersion;
        };
        xdg = {
          configFile = mkAliasDefinitions options.home.configFile;
          dataFile   = mkAliasDefinitions options.home.dataFile;
        };

        programs = mkAliasDefinitions options.home.programs;
      };
    };

    users.users.${config.user.name} = mkAliasDefinitions options.user;

    nix.settings = let users = [ "root" config.user.name ]; in {
      trusted-users = users;
      allowed-users = users;
    };
  };
}
