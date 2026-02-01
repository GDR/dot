{ self, pkgs, lib, overlays, ... }:
let
  # Import user defaults by name
  importUser = name: import ../_users/${name}.nix { inherit lib; };
in
{
  nix.enable = true;

  # Fix GID mismatch for existing Nix installation
  ids.gids.nixbld = 30000;


  # Enable user via hostUsers (new system)
  # Defaults from hosts/_users/<name>.nix, host-specific overrides here
  hostUsers.dgarifullin = importUser "dgarifullin" // {
    enable = true;
    # Host-specific: SSH key for this machine
    keys = [{
      name = "brightstar";
      type = "rsa";
      purpose = [ "git" "ssh" ];
      isDefault = true;
    }];
    # Hierarchical module enables
    modules = {
      home.browsers.enable = true;
      home.core.enable = true;
      home.desktop.enable = true; # was desktop-utils
      home.downloads.enable = true;
      home.editors.enable = true;
      home.messengers.enable = true;
      home.security.enable = true;
      home.shell.enable = true;
      home.terminal.enable = true;
    };
  };

  networking.hostName = "mac-brightstar";

  # System-scope modules (top-level, not in modules.*)
  systemAll = {
    # fonts.enable = true;
    nix-settings.enable = true;
    nix-gc.enable = true;
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
    app-aliases.enable = true; # Spotlight aliases for home-manager apps
  };

  time.timeZone = "Europe/Moscow";
}
