{ inputs, lib, config, pkgs, home-manager, hardware, ... }:
let
  # Import user defaults by name
  importUser = name: import ../../users/${name}.nix { inherit lib; };
in
{
  imports = [
    hardware.nixosModules.lenovo-thinkpad-t480
    ./hardware-configuration.nix
  ];

  networking.hostName = "nix-oldstar";

  # Enable user via hostUsers (system user account only, no home modules)
  hostUsers.dgarifullin = importUser "dgarifullin" // {
    enable = true;
    # Host-specific: SSH key for this machine
    keys = [{
      name = "oldstar";
      type = "rsa";
      purpose = [ "git" "ssh" ];
      isDefault = true;
    }];
    # SSH configuration
    ssh = [
      {
        host = "*";
        identityFile = "~/.ssh/oldstar_id_rsa";
        extraOptions.AddKeysToAgent = "yes";
      }
      {
        host = "github.com";
        user = "git";
        identityFile = "~/.ssh/oldstar_id_rsa";
      }
    ];
    # Minimal home modules - CLI tools and shell
    modules = {
      home.cli.enable = true;
      home.shell.zsh.enable = true;
    };
  };

  time.timeZone = "Europe/Moscow";

  # System-scope modules (server-side only)
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
      networkmanager.enable = true;
      openssh = {
        enable = true; # SSH server + charon-key AuthorizedKeysCommand
        userMap = { "dgarifullin" = "gdr"; }; # NixOS user -> GitHub username for charon-key
      };
      tailscale.enable = true;
    };
    editors.vscode-server.enable = true;
    graphics.intel = {
      enable = true;
      enableHybridCodec = true;
      tearFree = true;
    };
    power-management = {
      enable = true;
      tlp = true;
      upower = true;
      lidSwitch = "ignore";
    };
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 22 53 80 443 8080 8001 8081 ];
      allowedUDPPorts = [ 22 53 80 443 8080 8001 8081 ];
    };
    sound.enable = true;
  };
}
