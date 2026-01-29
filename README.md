# 🏠 Nix Configuration

[![NixOS](https://img.shields.io/badge/NixOS-25.11-5277C3?style=flat-square&logo=nixos&logoColor=white)](https://nixos.org/)
[![nix-darwin](https://img.shields.io/badge/nix--darwin-aarch64-000000?style=flat-square&logo=apple&logoColor=white)](https://github.com/LnL7/nix-darwin)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![CI](https://img.shields.io/github/check-runs/gdr/dot/master?style=flat-square&label=CI)](https://github.com/GDR/dot/actions)

Personal NixOS & nix-darwin configuration with a modular, tag-based architecture.

### Why Nix?

> *"Works on my machine"* → *"Works on every machine"*

Nix is a purely functional package manager that treats system configuration as code. The same configuration always produces the same system — whether you're setting up a fresh laptop or rebuilding after a disaster. Made a mistake? Just boot into a previous generation and you're back to a working state in seconds.

Everything is declarative: packages, services, dotfiles, even your desktop environment. No more scattered configs or forgotten setup steps. Your entire system lives in version-controlled `.nix` files that work across all your machines — Linux desktops, macOS laptops, headless servers.

Updates are atomic (they fully apply or don't touch anything), and different package versions coexist peacefully. No dependency hell, no "I updated X and now Y is broken". Just reproducible, reliable systems.

---

## ✨ Features

- 🖥️ **Multi-platform** — Same structure for NixOS and macOS (nix-darwin)
- 👥 **Multi-user ready** — Each user can have different tags/modules enabled
- 🏷️ **Tag-based modules** — Enable packages per-user with simple tags like `"editors-ui"`, `"games"`
- ⚙️ **Per-user module config** — Fine-grained control with `hostUsers.<name>.modules.<path>.enable`
- ✏️ **Live-editable dotfiles** — Config files are symlinked to this repo, edit in place without rebuild
- 🔍 **Auto-discovery** — Drop a `.nix` file in any module directory, it's automatically imported

---

## 📑 Table of Contents

- [Quick Start](#-quick-start)
- [Architecture](#-architecture)
  - [Directory Structure](#directory-structure)
  - [Module Types](#module-types)
- [Guides](#-guides)
  - [Create a New Host](#create-a-new-host)
  - [Create a New User](#create-a-new-user)
  - [Per-User Module Configuration](#per-user-module-configuration)
  - [Create a New Module](#create-a-new-module)
- [Host Configuration](#-host-configuration)
- [Tags Reference](#-tags-reference)
- [License](#-license)

---

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/gdr/dot.git ~/Workspaces/gdr/dot
cd ~/Workspaces/gdr/dot

# Apply configuration
# NixOS:
sudo nixos-rebuild switch --flake .#<hostname>

# macOS:
darwin-rebuild switch --flake .#<hostname>
```

---

## 🏗 Architecture

### Directory Structure

```
.
├── flake.nix                 # Entry point - defines hosts and imports
├── hosts/
│   ├── _users/               # User defaults (imported by hosts)
│   │   └── dgarifullin.nix
│   ├── nix-goldstar/         # NixOS host
│   │   ├── default.nix
│   │   └── hardware-configuration.nix
│   └── mac-italy/            # Darwin host
│       └── default.nix
├── lib/
│   ├── default.nix           # Helper functions (mkModule, mkDotfilesSymlink)
│   └── modules_v2/
│       ├── tags.nix          # Tag system options
│       └── user.nix          # hostUsers options & home-manager setup
├── modules_v2/
│   ├── _systemAll/           # Cross-platform system modules
│   │   ├── fonts.nix
│   │   ├── nix-gc.nix
│   │   ├── nix-settings.nix
│   │   └── shell/
│   │       ├── git.nix
│   │       └── ssh.nix
│   ├── _systemLinux/         # Linux-only system modules
│   │   ├── desktop/
│   │   │   ├── awesomewm/
│   │   │   └── hyprland/
│   │   ├── graphics/
│   │   ├── keyboards/
│   │   ├── networking/
│   │   └── sound.nix
│   ├── _systemDarwin/        # macOS-only system modules
│   └── common/               # User-level modules (enabled via tags)
│       ├── browsers/
│       ├── core/
│       ├── desktop/
│       ├── editors/
│       ├── games/
│       ├── media/
│       ├── messengers/
│       ├── security/
│       ├── shell/
│       └── terminal/
└── pkgs/                     # Custom packages
```

### Module Types

| Type | Location | Enabled via | Scope |
|------|----------|-------------|-------|
| **System (All)** | `_systemAll/` | `systemAll.<name>.enable` | System-wide, cross-platform |
| **System (Linux)** | `_systemLinux/` | `systemLinux.<name>.enable` | System-wide, Linux only |
| **System (Darwin)** | `_systemDarwin/` | `systemDarwin.<name>.enable` | System-wide, macOS only |
| **User** | `common/` | `hostUsers.<user>.tags.enable` or `hostUsers.<user>.modules.<path>.enable` | Per-user via tags or explicit config |

---

## 📖 Guides

### Create a New Host

1. **Create host directory:**

```bash
mkdir -p hosts/my-new-host
```

2. **Create `default.nix`:**

```nix
# hosts/my-new-host/default.nix
{ config, lib, pkgs, ... }:
let
  importUser = name: import ../_users/${name}.nix { inherit lib; };
in
{
  imports = [ ./hardware-configuration.nix ];

  # User configuration
  hostUsers.dgarifullin = importUser "dgarifullin" // {
    enable = true;
    keys = [{
      name = "my-new-host";
      type = "rsa";
      purpose = [ "git" "ssh" ];
      isDefault = true;
    }];
    tags.enable = [
      "core"
      "shells"
      "editors-terminal"
      # Add more tags as needed
    ];
    # Optional: Per-user module configuration
    # modules = {
    #   common.media.vlc.enable = true;
    #   common.editors.neovim.enable = true;
    # };
  };

  networking.hostName = "my-new-host";

  # System modules
  systemAll = {
    fonts.enable = true;
    nix-settings.enable = true;
    nix-gc.enable = true;
    shell.ssh.enable = true;
    shell.git.enable = true;
  };

  # Linux-specific (remove for Darwin)
  systemLinux = {
    desktop.hyprland.enable = true;
    networking.networkmanager.enable = true;
    sound.enable = true;
  };

  time.timeZone = "Europe/Moscow";
}
```

3. **Generate hardware config (NixOS):**

```bash
nixos-generate-config --show-hardware-config > hosts/my-new-host/hardware-configuration.nix
```

4. **Add to `flake.nix`:**

```nix
nixosConfigurations.my-new-host = mkNixosConfiguration ./hosts/my-new-host;
# or for Darwin:
darwinConfigurations.my-new-host = mkDarwinConfiguration ./hosts/my-new-host;
```

---

### Create a New User

1. **Create user defaults:**

```nix
# hosts/_users/newuser.nix
{ lib, ... }:
{
  enable = lib.mkDefault false;
  fullName = lib.mkDefault "New User";
  email = lib.mkDefault "newuser@example.com";
  github = lib.mkDefault "newuser";
  extraGroups = lib.mkDefault [ "wheel" "audio" "video" ];
}
```

2. **Enable in host config:**

```nix
# hosts/my-host/default.nix
hostUsers.newuser = importUser "newuser" // {
  enable = true;
  keys = [{
    name = "my-host";
    type = "rsa";
    purpose = [ "git" "ssh" ];
    isDefault = true;
  }];
  tags.enable = [ "core" "shells" ];
  # Per-user module configuration (alternative to tags)
  modules = {
    common.media.vlc.enable = true;
    common.editors.neovim.enable = true;
  };
};
```

---

### Per-User Module Configuration

In addition to tag-based enabling, you can explicitly configure modules per-user using the `modules` option:

```nix
hostUsers.dgarifullin = importUser "dgarifullin" // {
  enable = true;

  # Option 1: Enable via tags (enables all modules with matching tags)
  tags.enable = [ "media" "editors-terminal" ];

  # Option 2: Enable specific modules explicitly
  modules = {
    common.media.vlc.enable = true;
    common.editors.neovim.enable = true;
    common.browsers.chromium.enable = true;
  };

  # Both methods work together - modules are enabled if either condition is met
};
```

**When to use tags vs modules:**
- **Tags**: Enable multiple related modules at once (e.g., `"media"` enables vlc, spotify, etc.)
- **Modules**: Enable specific modules or override tag-based behavior for fine-grained control

Module paths follow the directory structure: `common.<category>.<module-name>`

---

### Create a New Module

#### User Module (tag-based)

```nix
# modules_v2/common/tools/my-tool.nix
{ config, pkgs, lib, system, _modulePath, ... }: with lib;
let
  mkModule = lib.my.mkModule system config;
  modulePath = _modulePath;
  moduleTags = [ "tools" ];  # Tag for enabling
in
{
  meta = lib.my.mkModuleMeta {
    tags = moduleTags;
    platforms = [ "linux" "darwin" ];
    description = "My awesome tool";
  };

  options = lib.my.mkModuleOptions modulePath {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config =
    let
      shouldEnable = lib.my.shouldEnableModule { inherit config modulePath moduleTags; };
    in
    mkIf shouldEnable (mkModule {
      # User packages (goes to home-manager.users.*)
      allSystems.home.packages = [ pkgs.my-tool ];

      # Darwin-specific
      darwinSystems.homebrew.casks = [ "my-tool" ];

      # Programs config (home-manager)
      nixosSystems.programs.my-tool.enable = true;
    });
}
```

#### System Module (Linux)

```nix
# modules_v2/_systemLinux/services/my-service.nix
{ config, pkgs, lib, ... }: with lib;
let
  cfg = config.systemLinux.services.my-service;
  enabledUsers = filterAttrs (_: u: u.enable) config.hostUsers;
in
{
  options.systemLinux.services.my-service = {
    enable = mkEnableOption "My service";
  };

  config = mkIf cfg.enable {
    # System-level NixOS options
    services.my-service.enable = true;

    # User packages via home-manager
    home-manager.users = mapAttrs (name: _: {
      home.packages = [ pkgs.my-tool-client ];
    }) enabledUsers;
  };
}
```

#### Auto-discovery

Modules are **auto-discovered** recursively! Just create your `.nix` file in the right directory and it's automatically imported. No manual import lists needed.

---

### Live-Editable Dotfiles

Store config files in the repo and symlink them so you can **edit without rebuilding**:

```
modules_v2/common/terminal/ghostty/
├── ghostty.nix
└── dotfiles/
    ├── config
    └── themes/
        └── catppuccin-mocha
```

In your module, use `mkDotfilesSymlink`:

```nix
{ config, pkgs, lib, self, ... }:
{
  config = mkIf cfg.enable (mkMerge [
    # Install the package
    (mkModule { allSystems.home.packages = [ pkgs.ghostty ]; })

    # Symlink dotfiles to ~/.config/ghostty (editable without rebuild!)
    {
      home-manager.users = lib.my.mkDotfilesSymlink {
        inherit config self;
        path = "ghostty";                                      # ~/.config/ghostty
        source = "modules_v2/common/terminal/ghostty/dotfiles"; # repo path
      };
    }
  ]);
}
```

Now `~/.config/ghostty` → `/path/to/repo/modules_v2/common/terminal/ghostty/dotfiles`

Edit the files directly, changes apply immediately (no `nixos-rebuild` needed)!

---

## 🖥 Host Configuration

| Host | Platform | Description |
|------|----------|-------------|
| `nix-goldstar` | NixOS | Desktop workstation with Hyprland |
| `mac-italy` | Darwin | MacBook Pro |
| `mac-blackstar` | Darwin | Mac Mini |

---

## 🏷 Tags Reference

Enable tags per-user in host config:

```nix
hostUsers.myuser.tags.enable = [ "core" "shells" "editors-ui" ];
```

| Tag | Modules |
|-----|---------|
| `core` | htop, shell-utils (bat, fzf, wget, direnv) |
| `shells` | zsh with oh-my-zsh, zplug, tmux |
| `terminal` | ghostty |
| `browsers` | chromium |
| `editors-ui` | cursor |
| `editors-terminal` | neovim (nixvim) |
| `desktop-utils` | rofi, dunst, brightnessctl, pamixer |
| `desktop-utils-wayland` | grim, slurp, wl-clipboard, waybar |
| `media` | vlc, spotify |
| `messengers` | telegram |
| `games` | steam, gamescope |
| `security` | keepassxc, bitwarden |
| `downloads` | qbittorrent |
| `oci-containers` | docker |

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.
