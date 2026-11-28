# lazygit - simple terminal UI for git commands
{ lib, ... }:

lib.my.mkFeature {
  description = "lazygit - simple terminal UI for git commands";
  cascade = false;

  homeModule = {
    programs.lazygit.enable = true;
  };
}
