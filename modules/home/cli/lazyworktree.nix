# lazyworktree - TUI for managing Git worktrees
{ lib, ... }:

lib.my.mkFeature {
  description = "lazyworktree - TUI for managing Git worktrees";
  cascade = false;

  homeModule = {
    programs.lazyworktree.enable = true;
  };
}
