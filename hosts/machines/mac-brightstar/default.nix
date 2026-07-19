{ self, inputs, pkgs, lib, overlays, ... }:
let
  importUser = name: import ../../users/${name}.nix { inherit lib; };
  userDefaults = importUser "dgarifullin";
  profiles = lib.my.mergeProfiles [
    (import ../../../profiles/developer.nix)
    (import ../../../profiles/desktop.nix)
  ];
in
{
  imports = [
    inputs.vantage.darwinModules.consul-dns # *.consul DNS via /etc/resolver/consul
  ];

  nix.enable = true;
  ids.gids.nixbld = 30000;

  hostUsers.dgarifullin = userDefaults.user // {
    enable = true;
    keys = [{
      name = "brightstar";
      type = "ed25519";
      purpose = [ "git" "ssh" ];
      isDefault = true;
    }];
    ssh = [
      {
        host = "*";
        identityFile = "~/.ssh/brightstar_id_ed25519";
        extraOptions.AddKeysToAgent = "yes";
      }
      {
        host = "github.com";
        user = "git";
        identityFile = "~/.ssh/brightstar_id_ed25519";
      }
    ] ++ userDefaults.ssh.knownHosts;
    modules = lib.recursiveUpdate profiles.userModules {
      home.ai-tools.enable = true;
      # home.utils.raycast.enable = true; # disabled: nixpkgs download URL broken
    };
  };

  networking.hostName = "mac-brightstar";
  environment.variables.DOTFILES_DIR = "/Users/dgarifullin/Workspaces/gdr/dot";

  # ── Remote builder: nix-oldstar (x86_64-linux) ─────────────────────
  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "nix-goldstar";
      sshUser = "dgarifullin";
      sshKey = "/etc/nix/brightstar-nixd_id_ed25519";
      system = "x86_64-linux";
      protocol = "ssh-ng";
      maxJobs = 16;
      speedFactor = 10;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    }
    {
      hostName = "nix-oldstar";
      sshUser = "dgarifullin";
      sshKey = "/etc/nix/brightstar-nixd_id_ed25519";
      system = "x86_64-linux";
      protocol = "ssh-ng";
      maxJobs = 8;
      speedFactor = 2;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    }
  ];

  modules.system.all = lib.recursiveUpdate profiles.system.all {
    sops.enable = true;
    # fonts.enable = true;  # disabled on Darwin
  };

  modules.system.darwin = {
    macos-settings.enable = true;
    homebrew = {
      enable = true;
      user = "dgarifullin";
    };
    app-aliases.enable = true;
    openssh = {
      enable = true;
      userMap = { "dgarifullin" = "gdr"; };
    };
  };

  modules.home.editors.antigravity = userDefaults.antigravity;

  time.timeZone = "Europe/Moscow";
  theme.name = "rose-pine-moon";

  services.vantage.consul-dns = {
    enable = true;
    nameserver = "100.64.100.3";
  };
}
