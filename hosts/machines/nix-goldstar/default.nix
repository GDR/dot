{ inputs, lib, config, pkgs, home-manager, hardware, ... }:
let
  importUser = name: import ../../users/${name}.nix { inherit lib; };
  userDefaults = importUser "dgarifullin";
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  hostUsers.dgarifullin = userDefaults.user // {
    enable = true;
    sudo.nopasswd = true;
    keys = [{
      name = "goldstar";
      type = "rsa";
      purpose = [ "git" "ssh" ];
      isDefault = true;
    }];
    ssh = [
      {
        host = "*";
        identityFile = "~/.ssh/goldstar_id_rsa";
        extraOptions.AddKeysToAgent = "yes";
      }
      {
        host = "github.com";
        user = "git";
        identityFile = "~/.ssh/goldstar_id_rsa";
      }
    ] ++ userDefaults.ssh.knownHosts;
    profiles = {
      developer.enable = true;
      desktop.enable = true;
      gaming.enable = true;
    };
    modules = {
      home.browsers.vivaldi.enable = true;
      home.desktop = {
        gnome.enable = true;
        hyprland.enable = true;
      };
      home.editors.neovim.enable = true;
      home.editors.ghidra.enable = true;
      home.editors.antigravity = {
        enable = true;
        mcpServers.ghidra = {
          command = "bridge-mcp-ghidra";
          args = [ ];
          env.GHIDRA_MCP_URL = "http://nix-oldstar:8089";
        };
      };
    };
  };

  networking.hostName = "nix-goldstar";
  environment.variables.DOTFILES_DIR = "/home/dgarifullin/Workspaces/gdr/dot";

  modules.system.all.fonts.enable = true;

  modules.system.linux = {
    networking.firewall.allowedTCPPorts = [ 8080 ];
    networking.openssh = {
      enable = true;
      userMap = { "*" = "gdr"; };
    };
    graphics.nvidia = {
      enable = true;
      open = true;
    };
  };

  time.timeZone = "Europe/Moscow";

  systemd.tmpfiles.rules = [
    "f /var/lib/systemd/linger/dgarifullin - - - -"
  ];

  theme.name = "catppuccin-macchiato";
}
