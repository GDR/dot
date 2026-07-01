{ inputs, lib, config, pkgs, home-manager, hardware, ... }:
let
  # Import user defaults by name
  importUser = name: import ../../users/${name}.nix { inherit lib; };
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  # Enable user via hostUsers (new system)
  # Defaults from hosts/users/<name>.nix, host-specific overrides here
  hostUsers.dgarifullin = importUser "dgarifullin" // {
    enable = true;
    # Passwordless sudo for remote deployment via SSH + nixos-rebuild
    sudo.nopasswd = true;
    # Host-specific: SSH key for this machine
    keys = [{
      name = "goldstar";
      type = "rsa";
      purpose = [ "git" "ssh" ];
      isDefault = true;
    }];
    # SSH client configuration
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
      {
        host = "nix-oldstar";
        forwardAgent = true;
      }
      {
        host = "nix-goldstar";
        forwardAgent = true;
      }
    ];
    # Hierarchical module enables
    modules = {
      home.browsers.vivaldi.enable = true;
      home.cli.enable = true;
      home.desktop = {
        # awesomewm.enable = true;
        # Desktop utilities (appearance, services, widgets)
        # Window manager (pick one)
        appearance.enable = true;
        gnome.enable = true;
        hyprland.enable = true;
        services.enable = true;
        utils.enable = true;
        utils.nautilus.enable = true;
        widgets.enable = true;
      };
      home.downloads.enable = true;
      home.editors.enable = true;
      home.editors.neovim.enable = true;
      home.games.lutris.enable = true;
      home.games.steam.enable = true;
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

  # System-scope modules (top-level, not in modules.*)
  systemAll = {
    fonts.enable = true;
    nix.settings.enable = true;
    nix.gc.enable = true;
    shell = {
      ssh.enable = true;
      git.enable = true;
    };
  };

  systemLinux = {
    networking = {
      firewall.enable = true;
      firewall.allowedTCPPorts = [ 8080 ];
      networkmanager.enable = true;
      openssh = {
        enable = true; # SSH server + charon-key AuthorizedKeysCommand
        userMap = { "*" = "gdr"; }; # NixOS user -> GitHub username for charon-key
      };
      tailscale.enable = true;
    };
    graphics.nvidia = {
      enable = true;
      open = true;
    };
    sound.enable = true;
  };

  time.timeZone = "Europe/Moscow";

  # Active color theme — consumed by all modules via lib.my.getTheme config
  theme.name = "catppuccin-macchiato";
}
