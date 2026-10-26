# Claude Code CLI tool
{ lib, ... }:

lib.my.mkFeature {
  description = "Claude Code CLI tool";
  homeModule = { pkgs, ... }: {
    home.packages = [ pkgs.claude-code ];
  };
}
