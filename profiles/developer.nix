# Developer profile — CLI tools, editors, shell, terminal, Docker
# Suitable for any machine where you write code.
{
  userModules = {
    home.cli.enable = true;
    home.editors.enable = true;
    home.shell.enable = true;
    home.terminal.enable = true;
    home.virtualisation.docker.enable = true;
  };

  system.all = {
    nix.settings.enable = true;
    nix.gc.enable = true;
    shell.git.enable = true;
    shell.ssh.enable = true;
  };
}
