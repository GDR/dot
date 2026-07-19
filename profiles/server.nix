# Server profile — minimal headless setup with common system baseline
# Suitable for NixOS servers, homelab nodes, remote builders.
{
  userModules = {
    home.cli.enable = true;
    home.editors.neovim.enable = true;
    home.shell.enable = true;
    home.virtualisation.docker.enable = true;
  };

  system.all = {
    fonts.enable = true;
    nix.settings.enable = true;
    nix.gc.enable = true;
    shell.git.enable = true;
    shell.ssh.enable = true;
  };

  system.linux = {
    networking.openssh.enable = true;
    networking.tailscale.enable = true;
    networking.firewall.enable = true;
    editors.vscode-server.enable = true;
  };
}
