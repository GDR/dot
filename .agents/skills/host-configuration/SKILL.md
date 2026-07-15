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
in
{
  imports = [ ./hardware-configuration.nix ];

  # User configuration
  hostUsers.dgarifullin = importUser "dgarifullin" // {
    enable = true;
    keys = [{
      name = "<hostname>";
      type = "rsa";           # rsa | ed25519
      purpose = [ "git" "ssh" ];
      isDefault = true;
    }];
    modules = {
      home.browsers.enable = true;
      home.cli.enable = true;
      home.desktop = {
        appearance.enable = true;
        services.enable = true;
        widgets.enable = true;
        utils.enable = true;
        hyprland.enable = true;
      };
      home.downloads.enable = true;
      home.editors.enable = true;
      home.games.enable = true;
      home.media.enable = true;
      home.messengers.enable = true;
      home.security.enable = true;
      home.shell.enable = true;
      home.terminal.enable = true;
      home.virtualisation.enable = true;
    };
  };

  networking.hostName = "<hostname>";

  systemAll = {
    fonts.enable = true;
    nix.settings.enable = true;
    nix.gc.enable = true;
    shell = { ssh.enable = true; git.enable = true; };
  };

  systemLinux = {
    networking = {
      networkmanager.enable = true;
      tailscale.enable = true;
    };
    graphics.nvidia.enable = true;
    sound.enable = true;
  };

  time.timeZone = "Europe/Moscow";
}
```

## Host Template (Darwin)

Same structure but replace `systemLinux` with `systemDarwin`:
```nix
systemDarwin = {
  homebrew.enable = true;
  macos-settings.enable = true;
};
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
# hosts/users/<username>.nix
{ lib, ... }: {
  fullName = lib.mkDefault "Full Name";
  email = lib.mkDefault "email@example.com";
  github = lib.mkDefault "github-username";
  extraGroups = lib.mkDefault [ "wheel" "networkmanager" "docker" ];
  # Keys are NOT in defaults — they are host-specific
}
```

## Adding a New Host

1. Create `hosts/machines/<hostname>/default.nix`
2. Create `hosts/machines/<hostname>/hardware-configuration.nix`
3. Add to `flake.nix`:
   ```nix
   nixosConfigurations.<hostname> = flakeHelpers.mkNixosConfiguration ./hosts/machines/<hostname>;
   # or for Darwin:
   darwinConfigurations.<hostname> = flakeHelpers.mkDarwinConfiguration ./hosts/machines/<hostname>;
   ```
4. Add Makefile target (optional)

## SSH Keys

Defined per-host in `hostUsers.<user>.keys`:
```nix
keys = [{
  name = "goldstar";       # Key identifier
  type = "rsa";            # rsa | ed25519
  purpose = [ "git" "ssh" ];  # "git" for signing, "ssh" for auth
  isDefault = true;        # Default key for this host
}];
```
Path convention: `~/.ssh/<name>_id_<type>` (e.g., `~/.ssh/goldstar_id_rsa`)

## Current Hosts

| Host | Platform | Flake attr | Rebuild command |
|------|----------|-----------|-----------------|
| `nix-goldstar` | NixOS | `nixosConfigurations.nix-goldstar` | `make nix-goldstar` (SSH) |
| `nix-oldstar` | NixOS | `nixosConfigurations.nix-oldstar` | `make nix-oldstar` (SSH, vantage override) |
| `mac-brightstar` | Darwin | `darwinConfigurations.mac-brightstar` | `make mac-brightstar` (local) |

## What Goes Where

| Setting | File |
|---------|------|
| User modules & keys | `default.nix` → `hostUsers.<user>.modules` |
| System modules | `default.nix` → `systemAll`/`systemLinux`/`systemDarwin` |
| Hostname, timezone | `default.nix` |
| Boot loader, kernel | `hardware-configuration.nix` |
| Filesystems | `hardware-configuration.nix` |
| Hardware drivers | `hardware-configuration.nix` or `systemLinux` modules |
