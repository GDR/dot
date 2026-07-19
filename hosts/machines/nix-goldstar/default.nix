{ inputs, lib, config, pkgs, home-manager, hardware, ... }:
let
  importUser = name: import ../../users/${name}.nix { inherit lib; };
  userDefaults = importUser "dgarifullin";
  profiles = lib.my.mergeProfiles [
    (import ../../../profiles/developer.nix)
    (import ../../../profiles/desktop.nix)
    (import ../../../profiles/gaming.nix)
  ];
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
    modules = lib.recursiveUpdate profiles.userModules {
      home.browsers.vivaldi.enable = true;
      home.desktop = {
        appearance.enable = true;
        gnome.enable = true;
        hyprland.enable = true;
        services.enable = true;
        utils.enable = true;
        utils.nautilus.enable = true;
        widgets.enable = true;
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

  modules.system.all = lib.recursiveUpdate profiles.system.all {
    fonts.enable = true;
  };

  modules.system.linux = lib.recursiveUpdate profiles.system.linux {
    networking.firewall.allowedTCPPorts = [ 8080 ];
    networking.openssh = {
      enable = true;
      userMap = { "*" = "gdr"; };
    };
    graphics.nvidia = {
      enable = true;
      open = true;
    };
    editors.vscode-server.enable = true;
  };

  time.timeZone = "Europe/Moscow";

  systemd.tmpfiles.rules = [
    "f /var/lib/systemd/linger/dgarifullin - - - -"
  ];

  theme.name = "catppuccin-macchiato";
}
