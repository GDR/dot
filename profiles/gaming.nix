# Gaming profile — Steam, Lutris, Soundpad
# Extend with desktop profile for a full gaming workstation.
{ lib, ... }:
{
  profileModules = {
    home.games.enable = lib.mkDefault true;
  };
}
