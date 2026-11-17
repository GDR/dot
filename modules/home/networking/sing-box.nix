# sing-box - Universal proxy platform (SFM NetworkExtension GUI + CLI on macOS)
{ lib, ... }:

lib.my.mkFeature {
  description = "sing-box universal proxy platform (SFM GUI + CLI on macOS)";
  platforms = [
    "linux"
    "darwin"
  ];

  homeModule = { pkgs, ... }: {
    home.packages = [ pkgs.sing-box ];
  };

  # SFM (https://sing-box.sagernet.org/clients/apple/) provides the signed macOS
  # NetworkExtension TUN client; nixpkgs only ships the headless CLI binary.
  darwinModule = {
    homebrew.casks = [ "sfm" ];
  };
}
