# Discord messenger
{ lib, ... }:

lib.my.mkFeature {
  description = "Discord desktop messenger";
  homeModule = _: {
    programs.discord.enable = true;
  };
}
