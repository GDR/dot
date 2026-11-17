# Project: NixOS Dotfiles (dot)

Personal NixOS & nix-darwin configuration with modular, hierarchical architecture.

## Architecture

```
dot/
├── flake.nix                 # Entry point — inputs, host declarations
├── docs/                     # Security architecture & operational runbook
├── hosts/
│   ├── users/                # User defaults (shared across hosts)
│   │   └── dgarifullin.nix
│   └── machines/             # Machine configurations
│       ├── nix-goldstar/     # NixOS desktop (Hyprland, NVIDIA)
│       ├── nix-oldstar/      # NixOS server & remote builder
│       └── mac-brightstar/   # Darwin workstation (clavis, nix-homebrew)
├── lib/
│   ├── default.nix           # Core helpers: mkFeature, mkSystemModuleV2, mergeProfiles, getTheme
│   ├── features.nix          # Feature descriptor & per-user compiler (mkFeature, dotfiles, etc.)
│   ├── flakeHelpers.nix      # mkDarwinConfiguration, mkNixosConfiguration
│   ├── moduleRegistry.nix    # Module discovery & transitive dependency resolver
│   └── themes/               # Theme system (rose-pine-moon, catppuccin-macchiato, etc.)
├── profiles/                 # Composable role bundles (developer, desktop, gaming, server, macos)
├── modules/
│   ├── _core/                # Core infrastructure
│   │   ├── registry.nix      # Module registry & feature catalog builder
│   │   ├── system.nix        # Tier-level system enable options
│   │   ├── theme.nix         # Global theme.name option
│   │   └── user.nix          # hostUsers option & per-user home-manager compilation
│   ├── home/                 # User features (auto-discovered, hierarchical enables)
│   │   ├── ai-tools/         # claude, codex, gemini-cli, learnharness
│   │   ├── browsers/         # chromium, vivaldi
│   │   ├── cli/              # gcloud, htop, shell-utils, vault
│   │   ├── desktop/          # appearance, awesomewm, hyprland, services, utils, widgets
│   │   ├── downloads/        # qbittorrent
│   │   ├── editors/          # antigravity, cursor, ghidra, neovim, vscode-server
│   │   ├── games/            # lutris, soundpad, steam
│   │   ├── media/            # iina, spotify, vlc
│   │   ├── messengers/       # telegram
│   │   ├── networking/       # sing-box
│   │   ├── security/         # bitwarden, clavis, keepassxc
│   │   ├── shell/            # git, ssh, tmux, zsh
│   │   ├── terminal/         # ghostty
│   │   ├── utils/            # logseq, macfuse, obsidian, raycast
│   │   └── virtualisation/   # docker, virtualbox
│   └── systems/              # System modules (auto-discovered, mkSystemModuleV2)
│       ├── all/              # Cross-platform (fonts, nix/{gc,settings}, shell/ssh, sops)
│       ├── linux/            # NixOS-only (graphics, keyboards, networking, power-management, sound)
│       └── darwin/           # macOS-only (homebrew, macos-settings, openssh, ssh)
├── overlays/                 # Nixpkgs overlays
├── pkgs/                     # Custom packages
└── templates/                # Flake templates
```

## Profiles

Role-based bundles of module enables. Compose multiple profiles per host.

```
profiles/
  developer.nix   # home: cli, editors, shell, terminal, docker + nix/ssh system baseline
  desktop.nix     # home: browsers, desktop infrastructure, downloads, media, messengers, security, utils
                  # system.linux: sound, networkmanager, tailscale, firewall
  gaming.nix      # home: games.*
  server.nix      # home: cli, shell, neovim, docker + system openssh/tailscale/firewall/vscode-server
  macos.nix       # system.darwin: macos-settings
```

### Using profiles in a host

```nix
let
  profiles = lib.my.mergeProfiles [
    (import ../../../profiles/developer.nix)
    (import ../../../profiles/desktop.nix)
    (import ../../../profiles/gaming.nix)
  ];
in {
  hostUsers.x.modules = lib.recursiveUpdate profiles.userModules {
    home.browsers.vivaldi.enable = true;  # host-specific additions
  };

  modules.system.all   = lib.recursiveUpdate profiles.system.all   { fonts.enable = true; };
  modules.system.linux = lib.recursiveUpdate profiles.system.linux { graphics.nvidia.enable = true; };
}
```

Use `lib.recursiveUpdate` (not `//`) to merge nested attrsets without clobbering siblings.

### Module dependency requires

Modules can declare `requires = [ "home.other.module" ]` in `mkFeature`. Enabling a module auto-enables its full transitive dependency tree — if A requires B and B requires C, enabling A auto-enables B and C. Inspect the registry: `nix eval '.#moduleRegistry.modules' --json`.

### Two module types

| Type | Location | Created with | Enabled via | Auto-discovered |
|------|----------|-------------|-------------|-----------------|
| User | `modules/home/` | `mkFeature` | `hostUsers.<user>.modules.<path>.enable` | Yes |
| System | `modules/systems/` | `mkSystemModuleV2` | `modules.system.all.*` / `modules.system.linux.*` / `modules.system.darwin.*` | Yes |

### Hierarchical enables — home modules

Module enabled if ANY of these is true:
- `modules.home.browsers.vivaldi.enable = true` (specific)
- `modules.home.browsers.enable = true` (category)
- `modules.home.enable = true` (all home)
- `hostUsers.<user>.modules.home.browsers.enable = true` (per-user)

Path follows directory structure: `modules/home/<category>/<module>` → `modules.home.<category>.<module>`

### Tier-level enables — system modules

System modules support a tier-level cascade. Setting the tier enables all modules within that platform:
- `modules.system.all.enable = true` — enables all cross-platform system modules
- `modules.system.linux.enable = true` — enables all Linux system modules
- `modules.system.darwin.enable = true` — enables all Darwin system modules

Individual module enables still work as before (and take precedence for opt-outs when the tier is on):
- `modules.system.all.fonts.enable = true` (specific module)
- `modules.system.linux.networking.openssh.enable = true` (specific module)

Path follows directory structure: `modules/systems/<platform>/<module>` → `modules.system.<platform>.<module>`

### Feature structure (mkFeature)

```nix
lib.my.mkFeature {
  description = "Feature description";
  platforms = [ "linux" "darwin" ];  # Supported platforms
  requires = [ "home.shell.zsh" ];   # Dependencies auto-enabled per user
  extraOptions = { ... };            # Per-user typed extra options

  dotfiles = {                       # Optional dotfiles management
    path = "app";
    source = "modules/home/.../dotfiles";
    # target = "~/.config/app";      # Optional explicit target (defaults to ~/.config/${path})
    # live = true;                   # Optional live-mode default override
  };

  homeModule = { config, osConfig, pkgs, lib, featureCfg, userName, ... }: {
    # Home Manager configuration scoped exclusively to this user
  };
  homeModuleLinux = { ... }: { ... };   # Linux-only HM config
  homeModuleDarwin = { ... }: { ... };  # Darwin-only HM config
  nixosModule = { config, pkgs, lib, featureCfg, selectedUsers, ... }: { ... };   # System-level NixOS activation
  darwinModule = { config, pkgs, lib, featureCfg, selectedUsers, ... }: { ... };  # System-level Darwin activation
};
```

Home-manager configuration is scoped strictly per-user to users who enable the feature.

## Key Helpers (lib/default.nix & lib/features.nix)

- `lib.my.mkFeature { description?, platforms?, requires?, extraOptions?, dotfiles?, homeModule?, homeModuleLinux?, homeModuleDarwin?, nixosModule?, darwinModule? }` — User feature descriptors
- `lib.my.mkSystemModuleV2 args { namespace, description?, module?, moduleLinux?, moduleDarwin?, extraOptions?, imports? }` — System modules
- `lib.my.mergeProfiles profiles` — Deep-merge profile attrsets (`userModules`, `system.{all,linux,darwin}`)
- `lib.my.isFeatureEnabledForUser { config, userName, featurePath?, modulePath? }` — Check per-user feature enable (hierarchy + transitive `requires`)
- `lib.my.resolveUserFeatures { osConfig, pkgs?, userName, userCfg, ... }` — Resolve active features for a user on the target platform
- `lib.my.getTheme config` — Get active theme (set via `config.theme.name`)

## Live-Editable Dotfiles

Store config files in `<module>/dotfiles/` and declare `dotfiles = { path; source; target?; live?; }` in `mkFeature` (target defaults to `~/.config/<path>`):
```
modules/home/terminal/ghostty/
├── ghostty.nix
└── dotfiles/
    └── config
```
Dotfiles default to immutable `/nix/store` mode (`live = false`) for generation rollback safety. Enable live out-of-store symlinks (`mkOutOfStoreSymlink`) globally via `dotfiles.live = true` or per feature via `modules.home.<cat>.<mod>.dotfilesLive = true` (or `hostUsers.<user>.modules.home.<cat>.<mod>.dotfilesLive = true`) so edits apply immediately without rebuilding.

Live mode uses `DOTFILES_DIR` environment variable set in host config (falling back to `~/dot`).

## Git Conventions (ZeroMQ C4)

```
<type>: <short description>

- Detail 1
- Detail 2
```

Types: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `style:`, `fmt:`
Optional scope: `refactor(flake):`, `feat(zsh):`

## Gotchas

- **git add before nix flake check** — Nix needs staged files
- **Don't mix** `programs.X.enable = true` with `home.packages = [ pkgs.X ]`
- **Boot/hardware config** → `hardware-configuration.nix`, NOT host `default.nix`
- **Home Manager paths** inside HM context: `programs.zsh` ✓, `home.programs.zsh` ✗
- **Desktop entries** for Rofi: use `xdg.desktopEntries.<app>` in home-manager context
- **Deprecated**: `programs.ssh.addKeysToAgent` → `programs.ssh.matchBlocks.*.addKeysToAgent`
- **Deprecated**: `programs.git.userEmail` → `programs.git.settings.user.email`

## Naming Conventions

- System dirs: `systems/{all,darwin,linux}`
- Module files: `modulename.nix` or `modulename/modulename.nix`
- Dotfiles: `modulename/dotfiles/`
- Host dirs: `hosts/machines/hostname/` (matches `networking.hostName`)
- User defaults: `hosts/users/username.nix`

## Current Hosts

| Host | Platform | Key features |
|------|----------|-------------|
| `nix-goldstar` | NixOS | Desktop, Hyprland, NVIDIA |
| `nix-oldstar` | NixOS | Server, remote builder |
| `mac-brightstar` | Darwin | MacBook, clavis, nix-homebrew |
