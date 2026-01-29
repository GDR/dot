# Linux system-scope modules - services, drivers, WM, networking
# These are enabled via systemLinux.* options, not via tags
{ ... }:
{
  imports = [
    ./desktop/awesomewm/awesomewm.nix
    ./desktop/hyprland/hyprland.nix
    ./graphics/nvidia.nix
    ./keyboards/keychron.nix
    ./networking/networkmanager.nix
    ./networking/tailscale.nix
    ./sound.nix
  ];
}
