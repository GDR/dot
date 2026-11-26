{ ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  system.stateVersion = "26.05";

  hostUsers.dgarifullin = {
    imports = [ ../../users/dgarifullin.nix ];
    enable = true;
    sudo.nopasswd = true;
    keys = [
      {
        name = "goldstar";
        type = "rsa";
        purpose = [
          "git"
          "ssh"
        ];
        isDefault = true;
      }
    ];
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
    ];
    modules = {
      home.ai-tools.agentic.enable = true;
      home.browsers.enable = true;
      home.browsers.vivaldi.enable = true;
      home.cli.enable = true;
      home.desktop = {
        appearance.enable = true;
        hyprland.enable = true;
        services.enable = true;
        utils.enable = true;
        widgets.enable = true;
      };
      home.downloads.enable = true;
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
          };
          ghidra = {
            command = "bridge-mcp-ghidra";
            args = [ ];
            # Ghidra runs locally on goldstar — MCP plugin listens on :8089
            env.GHIDRA_MCP_URL = "http://127.0.0.1:8089";
          };
          rea = {
            # pkgs.rea installed by antigravity module (from agentic flake)
            command = "rea";
            args = [ "mcp" ];
            env.REA_MCP_TOOL_CATALOG_PROFILE = "hot-cold";
          };
        };
      };
      home.games.enable = true;
      home.media.enable = true;
      home.messengers.enable = true;
      home.security.enable = true;
      home.shell.enable = true;
      home.terminal.enable = true;
      home.utils.enable = true;
      home.virtualisation.docker.enable = true;
    };
  };

  networking.hostName = "nix-goldstar";
  environment.variables.DOTFILES_DIR = "/home/dgarifullin/Workspaces/gdr/dot";

  modules.system.all = {
    fonts.enable = true;
    nix.gc.enable = true;
    nix.settings.enable = true;
    shell.ssh.enable = true;
  };

  modules.system.linux = {
    graphics.nvidia = {
      enable = true;
      open = true;
    };
    networking = {
      firewall = {
        enable = true;
        allowedTCPPorts = [ 8080 ];
      };
      networkmanager.enable = true;
      openssh = {
        enable = true;
        userMap = {
          "dgarifullin" = "gdr";
        };
      };
      tailscale.enable = true;
    };
    sound.enable = true;
  };

  time.timeZone = "Europe/Moscow";

  systemd.tmpfiles.rules = [
    "f /var/lib/systemd/linger/dgarifullin - - - -"
  ];

  theme.name = "catppuccin-macchiato";
}
