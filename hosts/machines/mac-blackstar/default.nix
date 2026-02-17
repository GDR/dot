{ self, pkgs, lib, overlays, ... }:
let
  # Import user defaults by name
  importUser = name: import ../../users/${name}.nix { inherit lib; };
in
{
  nix.enable = true;

  # Fix GID mismatch for existing Nix installation
  ids.gids.nixbld = 350;

  # Enable user via hostUsers (new system)
  # Defaults from hosts/users/<name>.nix, host-specific overrides here
  hostUsers.dgarifullin = importUser "dgarifullin" // {
    enable = true;
    # Host-specific: SSH key for this machine
    keys = [{
      name = "blackstar";
      type = "rsa";
      purpose = [ "git" "ssh" ];
      isDefault = true;
    }];
    # SSH configuration
    ssh = [
      {
        host = "*";
        identityFile = "~/.ssh/blackstar_id_rsa";
        extraOptions.AddKeysToAgent = "no"; # Darwin: use Touch ID prompt each time
      }
      {
        host = "github.com";
        user = "git";
        identityFile = "~/.ssh/blackstar_id_rsa";
      }
    ];
    # Hierarchical module enables
    modules = {
      home.browsers.enable = true;
      home.cli.enable = true;
      home.desktop.enable = true; # was desktop-utils
      home.editors.enable = true;
      home.messengers.enable = true;
      home.security.enable = true;
      home.shell.enable = true;
      home.terminal.enable = true;
    };
  };

  networking.hostName = "mac-blackstar";

  # System-scope modules (top-level, not in modules.*)
  systemAll = {
    # fonts.enable = true;
    nix.settings.enable = true;
    nix.gc.enable = true;
    shell = {
      ssh.enable = true;
      git.enable = true;
    };
  };

  # Darwin-specific system modules
  systemDarwin = {
    macos-settings.enable = true;
    homebrew = {
      enable = true;
      user = "dgarifullin";
    };
    # app-aliases.enable = true; # Spotlight aliases for home-manager apps
    openssh = {
      enable = true;
      userMap = { "dgarifullin" = "gdr"; };
    };
  };

  time.timeZone = "Europe/Moscow";
}
