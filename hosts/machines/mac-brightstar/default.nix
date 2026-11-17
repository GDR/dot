{ ... }:
{
  imports = [
    ../../../profiles/developer.nix
    ../../../profiles/desktop.nix
    ../../../profiles/macos.nix
  ];

  system.stateVersion = 5;
  nix.enable = true;
  ids.gids.nixbld = 30000;

  hostUsers.dgarifullin = {
    imports = [ ../../users/dgarifullin.nix ];
    enable = true;
    ssh = [
      {
        host = "github.com";
        user = "git";
      }
    ];
    modules = {
      home.editors.cursor.enable = true;
      home.editors.antigravity.enable = true;
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
          strong = {
            provider = "antigravity";
            id = "gemini-4-argon";
            thinkingLevel = "high";
          };
          cheap = {
            provider = "antigravity";
            id = "gemini-3.8-flash";
            thinkingLevel = "high";
          };
          vision = {
            provider = "antigravity";
            id = "gemini-4-argon";
            thinkingLevel = "medium";
          };
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
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
    }
    {
      hostName = "nix-oldstar";
      sshUser = "dgarifullin";
      sshKey = "/etc/nix/brightstar-nixd_id_ed25519";
      system = "x86_64-linux";
      protocol = "ssh-ng";
      maxJobs = 8;
      speedFactor = 2;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
    }
  ];

  modules.system.all.sops.enable = true;

  modules.system.darwin = {
    homebrew = {
      enable = true;
      user = "dgarifullin";
    };
    openssh = {
      enable = true;
      userMap = {
        "dgarifullin" = "gdr";
      };
    };
  };

  time.timeZone = "Europe/Moscow";
  theme.name = "rose-pine-moon";
}
