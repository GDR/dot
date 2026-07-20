# Developer profile module — CLI tools, editors, shell, terminal, Docker
# Per-user enable: hostUsers.<user>.profiles.developer.enable = true
{ lib, config, ... }:

let
  # Home modules this profile activates for any user who opts in.
  # Read by shouldEnableModule via config.modules.profiles.developer.homeModules.
  # Note: home.editors.enable is NOT used — it cascades to Linux-only editors (ghidra).
  # Hosts add specific editors (e.g. neovim, antigravity) directly in their modules.
  homeModules = {
    home.cli.enable = true;
    home.editors.neovim.enable = true;
    home.shell.enable = true;
    home.terminal.enable = true;
    home.virtualisation.docker.enable = true;
  };
in
{
  options.modules.profiles.developer.homeModules = lib.mkOption {
    type = lib.types.attrs;
    readOnly = true;
    internal = true;
    default = homeModules;
    description = "Home modules the developer profile enables (read by shouldEnableModule)";
  };

  config =
    let
      anyUserHasProfile = lib.any
        (u: u.profiles.developer.enable or false)
        (lib.attrValues (lib.filterAttrs (_: u: u.enable or false) config.hostUsers));
    in
    lib.mkIf anyUserHasProfile {
      modules.system.all = {
        nix.settings.enable = true;
        nix.gc.enable = true;
        shell.git.enable = true;
        shell.ssh.enable = true;
      };
    };
}
