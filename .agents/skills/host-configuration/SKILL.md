---
name: host-configuration
description: Configuring NixOS/Darwin hosts, adding users, managing host-specific settings
---

# Host Configuration

## Host Template (NixOS)

```nix
# hosts/machines/<hostname>/default.nix
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../../profiles/developer.nix
    ../../../profiles/desktop.nix
    # ../../../profiles/gaming.nix
  ];

  system.stateVersion = "26.05";

  hostUsers.dgarifullin = {
    imports = [ ../../users/dgarifullin.nix ];
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
    ];
    modules = {
      home.desktop.hyprland.enable = true;  # WM choice is host-specific
      home.editors.antigravity.enable = true;
    };
    sudo.nopasswd = true;                   # remove if not needed
  };

  networking.hostName = "<hostname>";
  environment.variables.DOTFILES_DIR = "/home/dgarifullin/Workspaces/gdr/dot";

  modules.system.all.fonts.enable = true;

  modules.system.linux = {
    networking.openssh = { enable = true; userMap = { "dgarifullin" = "gdr"; }; };
    graphics.nvidia = { enable = true; open = true; };
  };

  time.timeZone = "Europe/Moscow";
  theme.name = "catppuccin-macchiato";
}
```

## Host Template (Darwin)

```nix
{ ... }:
{
  imports = [
    ../../../profiles/developer.nix
    ../../../profiles/desktop.nix
    ../../../profiles/macos.nix
  ];

  system.stateVersion = 5;
  nix.enable = true;

  hostUsers.dgarifullin = {
    imports = [ ../../users/dgarifullin.nix ];
    enable = true;
    modules = {
      home.ai-tools.enable = true;
      home.security.clavis.enable = true;
      home.editors.antigravity.enable = true;
    };
  };

  networking.hostName = "<hostname>";
  environment.variables.DOTFILES_DIR = "/Users/dgarifullin/Workspaces/gdr/dot";

  modules.system.all.sops.enable = true;
  modules.system.darwin = {
    homebrew = { enable = true; user = "dgarifullin"; };
    openssh  = { enable = true; userMap = { "dgarifullin" = "gdr"; }; };
  };

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
# hosts/users/<username>.nix — host-invariant user module
{ lib, ... }: {
  fullName = lib.mkDefault "Full Name";
  email = lib.mkDefault "email@example.com";
  github = lib.mkDefault "github-username";
  extraGroups = [ "wheel" "audio" ];
  uid = lib.mkDefault 1000;            # explicit UID prevents collision if second user added
  stateVersion = lib.mkDefault "26.05";
  isPrimary = lib.mkDefault true;
  nixTrusted = lib.mkDefault true;
  inheritProfiles = lib.mkDefault true;

  ssh = [
    { host = "nix-oldstar"; forwardAgent = false; }
  ];
  modules.home.editors.antigravity.rules = lib.mkDefault ''...'';
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
5. Add `justfile` target (optional)

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
| `nix-goldstar` | NixOS | developer + desktop + gaming | `just nix-goldstar` |
| `nix-oldstar` | NixOS | server | `just nix-oldstar` |
| `mac-brightstar` | Darwin | developer + desktop + macos | `just mac-brightstar` |
