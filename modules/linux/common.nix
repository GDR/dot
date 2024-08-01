{ config, options, inputs, lib, nixpkgs, home-manager, ... }:
with lib;
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.nixvim.nixDarwinModules.nixvim
    inputs.vscode-server.nixosModules.default
  ];

  options = with types; { };

  config = {
    nixpkgs.config.allowUnfree = true;

    user =
      let
        user = builtins.getEnv "USER";
        name = if elem user [ "" "root" ] then "dgarifullin" else user;
      in
      {
        inherit name;
        extraGroups = [ "wheel" "audio" "libvirtd" ];
        isNormalUser = true;
        home = "/home/${name}";
        group = "users";
        uid = 1000;
      };

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;

      users.${config.user.name} = {
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

    users.users.${config.user.name} = mkAliasDefinitions options.user;

    nix.settings = let users = [ "root" config.user.name ]; in {
      trusted-users = users;
      allowed-users = users;
    };
  };
}
