# Discord messenger
{ lib, ... }:

lib.my.mkFeature {
  description = "Discord desktop messenger";
  homeModule = _: {
    programs.discord.enable = true;
    # Discord rewrites settings.json as a regular file on launch, which causes
    # Home Manager backup collisions on subsequent activations.
    xdg.configFile."discord/settings.json".force = true;
  };
}
