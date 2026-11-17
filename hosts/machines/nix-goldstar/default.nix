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
      home.desktop.hyprland.enable = true;
      home.editors.ghidra.enable = true;
      home.editors.antigravity = userDefaults.antigravity // {
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
      userMap = { "dgarifullin" = "gdr"; };
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
