# LearnHarness - An agent harness for learning
{ lib, ... }:

lib.my.mkFeature {
  platforms = [
    "linux"
    "darwin"
  ];
  description = "LearnHarness - An agent harness for learning";
  homeModule = { pkgs, ... }: {
    home.packages = [ pkgs.learnharness ];
  };
}
