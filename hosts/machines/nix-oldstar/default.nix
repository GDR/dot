{ lib, hardware, ... }:
let
  importUser = name: import ../../users/${name}.nix { inherit lib; };
  userDefaults = importUser "dgarifullin";
  profiles = lib.my.mergeProfiles [
    (import ../../../profiles/server.nix)
  ];
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
    trusted-users = [ "@wheel" ];
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
    modules = lib.recursiveUpdate profiles.userModules {
      home.editors.ghidra.enable = true;
    };
    sudo.nopasswd = true;
  };

  time.timeZone = "Europe/Moscow";

  modules.system.all = lib.recursiveUpdate profiles.system.all {
    sops.enable = true;
  };

  modules.system.linux = lib.recursiveUpdate profiles.system.linux {
    networking.networkmanager.enable = true;
    # server profile enables tailscale by default; oldstar runs on LAN only
    networking.tailscale.enable = false;
    networking.openssh.userMap = { "dgarifullin" = "gdr"; };
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
      allowedTCPPorts = [ 22 80 443 8080 ];
      allowedUDPPorts = [ 80 443 8080 ];
    };
    sound.enable = true;
  };
}
