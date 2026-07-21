{ self, inputs, pkgs, lib, overlays, ... }:
let
  importUser = name: import ../../users/${name}.nix { inherit lib; };
  userDefaults = importUser "dgarifullin";
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
    modules = {
      # developer profile
      home.cli.enable = true;
      home.editors.neovim.enable = true;
      home.shell.enable = true;
      home.terminal.enable = true;
      home.virtualisation.docker.enable = true;
      # desktop profile
      home.browsers.enable = true;
      home.desktop.appearance.enable = true;
      home.desktop.services.enable = true;
      home.desktop.utils.enable = true;
      home.desktop.widgets.enable = true;
      home.downloads.enable = true;
      home.media.enable = true;
      home.messengers.enable = true;
      home.security.enable = true;
      home.utils.enable = false;
      # host-specific
      home.ai-tools.enable = true;
      home.editors.antigravity = { enable = true; } // userDefaults.antigravity;
      home.utils.raycast.enable = false; # disabled: nixpkgs download URL broken
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

  modules.system.all = {
    nix.settings.enable = true;
    nix.gc.enable = true;
    shell.git.enable = true;
    shell.ssh.enable = true;
    sops.enable = true;
    # fonts.enable = true;  # disabled on Darwin
  };

  modules.system.darwin = {
    macos-settings.enable = true;
    app-aliases.enable = true;
    homebrew = {
      enable = true;
      user = "dgarifullin";
    };
    openssh = {
      enable = true;
      userMap = { "dgarifullin" = "gdr"; };
    };
  };

  modules.home.editors.antigravity = { enable = true; } // userDefaults.antigravity;

  time.timeZone = "Europe/Moscow";
  theme.name = "rose-pine-moon";

  services.vantage.consul-dns = {
    enable = true;
    nameserver = "100.64.100.3";
  };
}
