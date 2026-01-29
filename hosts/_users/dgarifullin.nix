# Default values for dgarifullin user
# This file provides defaults that can be overridden via hostUsers.dgarifullin.<option>
{ lib, ... }:

{
  fullName = lib.mkDefault "Damir Garifullin";
  email = lib.mkDefault "gosugdr@gmail.com";
  github = lib.mkDefault "gdr";
  extraGroups = lib.mkDefault [ "wheel" "audio" "libvirtd" "input" ];
  
  # Keys will be set per-host since each host has different key names
  # keys = lib.mkDefault [];
}
