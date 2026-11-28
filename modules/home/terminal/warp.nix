# Warp terminal
{ lib, ... }:

lib.my.mkFeature {
  description = "Warp terminal";
  platforms = [
    "linux"
    "darwin"
  ];

  homeModule =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.warp ];
    };
}
