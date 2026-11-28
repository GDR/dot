# Discord messenger
{ lib, ... }:

lib.my.mkFeature {
  description = "Discord desktop messenger";
  homeModule =
    { config, pkgs, ... }:
    let
      configDir =
        if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else config.xdg.configHome;
    in
    {
      programs.discord.enable = true;
      # Discord rewrites settings.json as a regular file on launch, which causes
      # Home Manager backup collisions on subsequent activations.
      home.file."${configDir}/${config.programs.discord.configName}/settings.json".force = true;
    };
}
