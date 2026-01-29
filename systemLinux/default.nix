# Linux system-scope modules - services, drivers, WM, networking
# These are enabled via systemLinux.* options, not via tags
{ ... }:
{
  imports = [
    ./networking/networkmanager.nix
    ./networking/tailscale.nix
  ];
}
