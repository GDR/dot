# Server profile — minimal headless setup with common system baseline
# Suitable for NixOS servers, homelab nodes, remote builders.
{ lib, system, ... }:
{
  profileModules = {
    home.cli.enable = lib.mkDefault true;
    home.editors.neovim.enable = lib.mkDefault true;
    home.editors.vscode-server.enable = lib.mkDefault true;
    home.shell.enable = lib.mkDefault true;
    home.virtualisation.docker.enable = lib.mkDefault true;
  };

  modules.system.all = {
    fonts.enable = lib.mkDefault true;
    nix.settings.enable = lib.mkDefault true;
    nix.gc.enable = lib.mkDefault true;
    shell.ssh.enable = lib.mkDefault true;
  };
} // lib.optionalAttrs (lib.hasSuffix "-linux" system) {
  modules.system.linux = {
    networking.openssh.enable = lib.mkDefault true;
    networking.tailscale.enable = lib.mkDefault true;
    networking.firewall.enable = lib.mkDefault true;
  };
}
