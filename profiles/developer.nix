# Developer profile — CLI tools, editors, shell, terminal, Docker
# Suitable for any machine where you write code.
{
  userModules = {
    home.cli.enable = true;
    # Intentionally NOT setting home.editors.enable broadly: home.editors also
    # contains GUI IDEs, reverse-engineering tools, and remote daemons (cursor,
    # antigravity, ghidra, vscode-server) that should be chosen per host.
    home.editors.neovim.enable = true;
    home.shell.enable = true;
    home.terminal.enable = true;
    home.virtualisation.docker.enable = true;
  };

  system.all = {
    nix.settings.enable = true;
    nix.gc.enable = true;
    shell.ssh.enable = true;
  };
}
