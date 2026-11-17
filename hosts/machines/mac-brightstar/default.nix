{ lib, ... }:
let
  importUser = name: import ../../users/${name}.nix { inherit lib; };
  userDefaults = importUser "dgarifullin";
  profiles = lib.my.mergeProfiles [
    (import ../../../profiles/developer.nix)
    (import ../../../profiles/desktop.nix)
    (import ../../../profiles/macos.nix)
  ];
in
{
  nix.enable = true;
  ids.gids.nixbld = 30000;

  hostUsers.dgarifullin = userDefaults.user // {
    enable = true;
    ssh = [
      {
        host = "github.com";
        user = "git";
      }
    ] ++ userDefaults.ssh.knownHosts;
    modules = lib.recursiveUpdate profiles.userModules {
      home.editors.cursor.enable = true;
      home.editors.antigravity = { enable = true; } // userDefaults.antigravity;
      home.networking.sing-box.enable = true;
      home.security.clavis.enable = true;
      # desktop profile enables home.utils broadly; select Darwin-supported utils explicitly
      home.utils.enable = false;
      home.utils.obsidian.enable = true;
      home.utils.logseq.enable = true;
      home.utils.raycast.enable = false; # disabled: nixpkgs download URL broken
      home.ai-tools.enable = true;
      home.ai-tools.learnharness = {
        enable = true;
        autoUpdate = false;
        obsidianFolders = [ "/Users/dgarifullin/obsidian-vault" ];
        models = {
          strong = { provider = "antigravity"; id = "gemini-4-argon"; thinkingLevel = "high"; };
          cheap = { provider = "antigravity"; id = "gemini-3.8-flash"; thinkingLevel = "high"; };
          vision = { provider = "antigravity"; id = "gemini-4-argon"; thinkingLevel = "medium"; };
        };
      };
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

  modules.system.darwin = lib.recursiveUpdate profiles.system.darwin {
    homebrew = {
      enable = true;
      user = "dgarifullin";
    };
    openssh = {
      enable = true;
      userMap = { "dgarifullin" = "gdr"; };
    };
  };


  time.timeZone = "Europe/Moscow";
  theme.name = "rose-pine-moon";
}
