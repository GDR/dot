{ lib, hardware, ... }:
let
  importUser = name: import ../../users/${name}.nix { inherit lib; };
  userDefaults = importUser "dgarifullin";
in
{
  imports = [
    hardware.nixosModules.lenovo-thinkpad-t480
    ./hardware-configuration.nix
  ];

  networking.hostName = "nix-oldstar";
  environment.variables.DOTFILES_DIR = "/home/dgarifullin/Workspaces/gdr/dot";

  # Enable nix-oldstar to act as a Nix remote builder for mac-brightstar
  nix.settings = {
    trusted-users = [ "root" "@wheel" ];
    max-jobs = "auto";
    system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
  };

  hostUsers.dgarifullin = userDefaults.user // {
    enable = true;
    keys = [{
      name = "oldstar";
      type = "ed25519";
      purpose = [ "git" "ssh" ];
      isDefault = true;
    }];
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
    ] ++ userDefaults.ssh.knownHosts;
    modules = {
      # server profile
      home.cli.enable = true;
      home.editors.neovim.enable = true;
      home.editors.vscode-server.enable = true;
      home.shell.enable = true;
      home.virtualisation.docker.enable = true;
      # host-specific
      home.editors.ghidra.enable = true;
    };
    sudo.nopasswd = true;
  };

  time.timeZone = "Europe/Moscow";

  modules.system.all = {
    nix.settings.enable = true;
    nix.gc.enable = true;
    fonts.enable = true;
    shell.ssh.enable = true;
    sops.enable = true;
  };

  modules.system.linux = {
    networking.networkmanager.enable = true;
    networking.openssh = {
      enable = true;
      userMap = { "dgarifullin" = "gdr"; };
    };
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
      # 8089: GhidraMCP HTTP server (goldstar bridge → oldstar Ghidra)
      allowedTCPPorts = [ 22 80 443 8080 8089 ];
      allowedUDPPorts = [ 22 80 443 8080 ];
    };
    sound.enable = true;
  };
}
