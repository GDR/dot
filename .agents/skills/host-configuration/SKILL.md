---
name: host-configuration
description: Configuring NixOS/Darwin hosts, adding users, managing host-specific settings
---

# Host Configuration

## Host Template (NixOS)

```nix
# hosts/machines/<hostname>/default.nix
{ inputs, lib, config, pkgs, home-manager, hardware, ... }:
let
  importUser = name: import ../../users/${name}.nix { inherit lib; };
  userDefaults = importUser "dgarifullin";
  profiles = lib.my.mergeProfiles [
    (import ../../../profiles/developer.nix)
    (import ../../../profiles/desktop.nix)
    # (import ../../../profiles/gaming.nix)
  ];
in
{
  imports = [ ./hardware-configuration.nix ];

  hostUsers.dgarifullin = userDefaults.user // {
    enable = true;
    keys = [{
      name = "<hostname>";
      type = "ed25519";       # rsa | ed25519
      purpose = [ "git" "ssh" ];
      isDefault = true;
    }];
    ssh = [
      { host = "*"; identityFile = "~/.ssh/<hostname>_id_ed25519"; extraOptions.AddKeysToAgent = "yes"; }
      { host = "github.com"; user = "git"; identityFile = "~/.ssh/<hostname>_id_ed25519"; }
    ] ++ userDefaults.ssh.knownHosts;
    modules = lib.recursiveUpdate profiles.userModules {
      home.desktop.hyprland.enable = true;  # WM choice is host-specific
    };
    sudo.nopasswd = true;                   # remove if not needed
  };

  networking.hostName = "<hostname>";
  environment.variables.DOTFILES_DIR = "/home/dgarifullin/Workspaces/gdr/dot";

  modules.system.all = lib.recursiveUpdate profiles.system.all {
    fonts.enable = true;
  };

  modules.system.linux = lib.recursiveUpdate profiles.system.linux {
    networking.openssh = { enable = true; userMap = { "dgarifullin" = "gdr"; }; };
    graphics.nvidia   = { enable = true; open = true; };
  };

  modules.home.editors.antigravity = userDefaults.antigravity;
  time.timeZone = "Europe/Moscow";
  theme.name = "catppuccin-macchiato";
}
```

## Host Template (Darwin)

```nix
{ self, inputs, pkgs, lib, overlays, ... }:
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

  hostUsers.dgarifullin = userDefaults.user // {
    enable = true;
    keys = [{ name = "<hostname>"; type = "ed25519"; purpose = [ "git" "ssh" ]; isDefault = true; }];
    ssh = [
      { host = "*"; identityFile = "~/.ssh/<hostname>_id_ed25519"; extraOptions.AddKeysToAgent = "yes"; }
      { host = "github.com"; user = "git"; identityFile = "~/.ssh/<hostname>_id_ed25519"; }
    ] ++ userDefaults.ssh.knownHosts;
    modules = lib.recursiveUpdate profiles.userModules {
      home.ai-tools.enable = true;
    };
  };

  networking.hostName = "<hostname>";
  environment.variables.DOTFILES_DIR = "/Users/dgarifullin/Workspaces/gdr/dot";

  modules.system.all = lib.recursiveUpdate profiles.system.all { sops.enable = true; };
  modules.system.darwin = lib.recursiveUpdate profiles.system.darwin {
    homebrew = { enable = true; user = "dgarifullin"; };
    openssh  = { enable = true; userMap = { "dgarifullin" = "gdr"; }; };
  };

  modules.home.editors.antigravity = userDefaults.antigravity;
  time.timeZone = "Europe/Moscow";
  theme.name = "rose-pine-moon";
}
```

## Hardware Configuration

```nix
# hosts/machines/<hostname>/hardware-configuration.nix
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/" = { ... };
  hardware.cpu.intel.updateMicrocode = true;
}
```

Generate: `nixos-generate-config --show-hardware-config`

## User Defaults

```nix
# hosts/users/<username>.nix — host-invariant user data
{ lib, ... }: {
  user = {
    fullName = "Full Name";
    email    = "email@example.com";
    github   = "github-username";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    uid = 1000;                       # explicit UID prevents drift if second user added
  };
  ssh.knownHosts = [                  # topology entries shared across all hosts
    { host = "nix-oldstar"; forwardAgent = true; }
  ];
  antigravity = { rules = ''...''; cavemanEnable = true; };
}
```

## Adding a New Host

1. Create `hosts/machines/<hostname>/default.nix` using the template above
2. Create `hosts/machines/<hostname>/hardware-configuration.nix`
3. Add to `flake.nix`:
   ```nix
   nixosConfigurations.<hostname> = flakeHelpers.mkNixosConfiguration ./hosts/machines/<hostname>;
   # or for Darwin:
   darwinConfigurations.<hostname> = flakeHelpers.mkDarwinConfiguration ./hosts/machines/<hostname>;
   ```
4. Pick profiles — `developer` for any machine, `desktop` for GUI, `server` for headless
5. Add Makefile target (optional)

## SSH Keys

Defined per-host in `hostUsers.<user>.keys`. Path convention: `~/.ssh/<name>_id_<type>`.

```nix
keys = [{
  name = "goldstar";       # Key identifier
  type = "ed25519";        # rsa | ed25519
  purpose = [ "git" "ssh" ];
  isDefault = true;
}];
```

## What Goes Where

| Setting | File |
|---------|------|
| User modules & keys | `default.nix` → `hostUsers.<user>.modules` (via profiles) |
| System modules | `default.nix` → `modules.system.{all,linux,darwin}` (via profiles) |
| Hostname, timezone, theme | `default.nix` |
| Boot loader, kernel | `hardware-configuration.nix` |
| Filesystems, hardware drivers | `hardware-configuration.nix` |

## Current Hosts

| Host | Platform | Profiles | Rebuild command |
|------|----------|----------|-----------------|
| `nix-goldstar` | NixOS | developer + desktop + gaming | `make nix-goldstar` |
| `nix-oldstar` | NixOS | server | `make nix-oldstar` |
| `mac-brightstar` | Darwin | developer + desktop + macos | `make mac-brightstar` |
