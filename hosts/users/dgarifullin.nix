# Default user module for dgarifullin
# Import inside hostUsers.dgarifullin = { imports = [ ../../users/dgarifullin.nix ]; ... };
{ lib, ... }:

{
  fullName = lib.mkDefault "Damir Garifullin";
  email = lib.mkDefault "gosugdr@gmail.com";
  github = lib.mkDefault "gdr";
  uid = lib.mkDefault 1000;
  stateVersion = lib.mkDefault "26.05";
  isPrimary = lib.mkDefault true;
  nixTrusted = lib.mkDefault true;
  extraGroups = [
    "wheel"
    "audio"
  ];

  # SSH topology — host-invariant entries merged into each machine's ssh list.
  # Keys and identity files are specified per host.
  ssh = [
    {
      host = "nix-oldstar";
      forwardAgent = false;
    }
    {
      host = "nix-goldstar";
      forwardAgent = false;
    }
  ];
}
