# Server profile module — minimal headless setup with common system baseline
# Per-user enable: hostUsers.<user>.profiles.server.enable = true
{ lib, config, system, ... }:

let
  isLinux = system == "x86_64-linux" || system == "aarch64-linux";

  homeModules = {
    home.cli.enable = true;
    home.editors.neovim.enable = true;
    home.editors.vscode-server.enable = true;
    home.shell.enable = true;
    home.virtualisation.docker.enable = true;
  };
in
{
  options.modules.profiles.server.homeModules = lib.mkOption {
    type = lib.types.attrs;
    readOnly = true;
    internal = true;
    default = homeModules;
    description = "Home modules the server profile enables (read by shouldEnableModule)";
  };

  config =
    let
      anyUserHasProfile = lib.any
        (u: u.profiles.server.enable or false)
        (lib.attrValues (lib.filterAttrs (_: u: u.enable or false) config.hostUsers));
    in
    lib.mkIf anyUserHasProfile (
      {
        modules.system.all = {
          fonts.enable = true;
          shell.git.enable = true;
          shell.ssh.enable = true;
        };
      } // lib.optionalAttrs isLinux {
        modules.system.linux = {
          networking.openssh.enable = true;
          networking.tailscale.enable = true;
          networking.firewall.enable = true;
        };
      }
    );
}
