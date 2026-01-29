# Cross-platform system-scope modules (Linux + Darwin)
# These are enabled via systemAll.* options
{ ... }:
{
  imports = [
    ./shell/ssh.nix
    ./shell/git.nix
    ./nix-gc.nix
    ./nix-settings.nix
  ];
}
