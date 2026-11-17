# Developer profile — CLI tools, editors, shell, terminal, Docker
# Suitable for any machine where you write code.
{ lib, ... }:
{
  profileModules = {
    home.cli.enable = lib.mkDefault true;
    # Intentionally NOT setting home.editors.enable broadly: home.editors also
    # contains GUI IDEs, reverse-engineering tools, and remote daemons (cursor,
    # antigravity, ghidra, vscode-server) that should be chosen per host.
    home.editors.neovim.enable = lib.mkDefault true;
    home.shell.enable = lib.mkDefault true;
    home.terminal.enable = lib.mkDefault true;
    home.virtualisation.docker.enable = lib.mkDefault true;
  };

  modules.system.all = {
    nix.settings.enable = lib.mkDefault true;
    nix.gc.enable = lib.mkDefault true;
    shell.ssh.enable = lib.mkDefault true;
  };
}
