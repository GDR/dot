# Default values for dgarifullin user
# Import in hosts and merge with host-specific overrides:
#   hostUsers.dgarifullin = userDefaults // { enable = true; keys = [...]; };
{ lib, ... }:

{
  fullName = "Damir Garifullin";
  email = "gosugdr@gmail.com";
  github = "gdr";
  extraGroups = [ "wheel" "audio" "libvirtd" "input" ];
}
