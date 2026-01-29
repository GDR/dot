# Cross-platform system-scope modules (Linux + Darwin)
# These are enabled via systemAll.* options
{ ... }:
{
  imports = [
    ./shell/ssh.nix
    ./nix-gc.nix
    ./nix-settings.nix
  ];
}
