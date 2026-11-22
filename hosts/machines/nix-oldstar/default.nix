{ hardware, ... }:
{
  imports = [
    hardware.nixosModules.lenovo-thinkpad-t480
    ./hardware-configuration.nix
  ];

  system.stateVersion = "26.05";

  networking.hostName = "nix-oldstar";
  environment.variables.DOTFILES_DIR = "/home/dgarifullin/Workspaces/gdr/dot";

  # Enable nix-oldstar to act as a Nix remote builder for mac-brightstar
  nix.settings = {
    trusted-users = [ "@wheel" ];
    max-jobs = "auto";
    system-features = [
      "nixos-test"
      "benchmark"
      "big-parallel"
      "kvm"
    ];
  };

  hostUsers.dgarifullin = {
    imports = [ ../../users/dgarifullin.nix ];
    enable = true;
    keys = [
      {
        name = "oldstar";
        type = "ed25519";
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
        identityFile = "~/.ssh/oldstar_id_ed25519";
        extraOptions.AddKeysToAgent = "yes";
      }
      {
        host = "github.com";
        user = "git";
        identityFile = "~/.ssh/oldstar_id_ed25519";
      }
    ];
    modules = {
      home.cli.enable = true;
      home.editors.ghidra.enable = true;
      home.editors.neovim.enable = true;
      home.editors.vscode-server.enable = true;
      home.shell.enable = true;
      home.virtualisation.docker.enable = true;
    };
    sudo.nopasswd = true;
  };

  time.timeZone = "Europe/Moscow";

  modules.system.all = {
    fonts.enable = true;
    nix.gc.enable = true;
    nix.settings.enable = true;
    shell.ssh.enable = true;
    sops.enable = true;
  };

  modules.system.linux = {
    networking.networkmanager.enable = true;
    # oldstar runs on LAN only
    networking.tailscale.enable = false;
    networking.openssh = {
      enable = true;
      userMap = {
        "dgarifullin" = "gdr";
      };
    };
    graphics.intel = {
      enable = true;
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
      allowedTCPPorts = [
        22
        80
        443
        8080
      ];
      allowedUDPPorts = [
        80
        443
        8080
      ];
    };
    sound.enable = true;
  };
}
