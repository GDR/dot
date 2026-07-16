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
    modules = {
      # developer profile
      home.cli.enable = true;
      home.shell.enable = true;
      home.terminal.enable = true;
      home.virtualisation.docker.enable = true;
      # desktop profile
      home.browsers.enable = true;
      home.desktop.appearance.enable = true;
      home.desktop.services.enable = true;
      home.desktop.utils.enable = true;
      home.desktop.widgets.enable = true;
      home.downloads.enable = true;
      home.media.enable = true;
      home.messengers.enable = true;
      home.security.enable = true;
      home.utils.enable = true;
      # gaming profile
      home.games.enable = true;
      # host-specific
      home.browsers.vivaldi.enable = true;
      home.desktop = {
        gnome.enable = true;
        hyprland.enable = true;
      };
      home.editors.neovim.enable = true;
      home.editors.ghidra.enable = true;
      home.editors.antigravity = {
        enable = true;
        # Global MCP servers — written to ~/.gemini/antigravity/mcp_config.json
        # Applies to ALL workspaces opened in Antigravity IDE
        mcpServers = {
          nixos = {
            # pkgs.mcp-nixos installed by antigravity module — direct binary, no nix run overhead
            command = "mcp-nixos";
            args = [ ];
          };
          context7 = {
            url = "https://mcp.context7.com/mcp";
            headers.CONTEXT7_API_KEY = "\${env.CONTEXT7_API_KEY}";
          };
          ghidra = {
            command = "bridge-mcp-ghidra";
            args = [ ];
            env.GHIDRA_MCP_URL = "http://nix-goldstar:8089";
          };
        };
      };
    };
  };

  networking.hostName = "nix-goldstar";
  environment.variables.DOTFILES_DIR = "/home/dgarifullin/Workspaces/gdr/dot";

  modules.system.all = {
    nix.settings.enable = true;
    nix.gc.enable = true;
    fonts.enable = true;
  };

  modules.system.all = {
    shell.git.enable = true;
    shell.ssh.enable = true;
  };

  modules.system.linux = {
    sound.enable = true;
    networking.networkmanager.enable = true;
    networking.tailscale.enable = true;
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 8080 ];
    };
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
