# Terax AI-native terminal (ADE)
{ lib, ... }:

lib.my.mkFeature {
  description = "Terax AI-native terminal";
  platforms = [
    "linux"
    "darwin"
  ];

  homeModule =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.terax ];
    };
}
