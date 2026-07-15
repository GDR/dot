# Project: NixOS Dotfiles (dot)

Personal NixOS & nix-darwin configuration with modular, hierarchical architecture.

## Architecture

```
dot/
├── flake.nix                 # Entry point — inputs, host declarations
├── hosts/
│   ├── users/                # User defaults (shared across hosts)
│   │   └── dgarifullin.nix
│   └── machines/             # Machine configurations
│       ├── nix-goldstar/     # NixOS desktop (Hyprland, NVIDIA)
│       ├── nix-oldstar/      # NixOS host
│       └── mac-brightstar/   # Darwin host
├── lib/
│   ├── default.nix           # Core helpers: mkModuleV2, mkSystemModuleV2, mkDotfilesSymlink, etc.
│   ├── flakeHelpers.nix      # mkDarwinConfiguration, mkNixosConfiguration
│   ├── moduleRegistry.nix    # Module discovery/registry
│   └── themes/               # Theme system (rose-pine-moon, etc.)
├── modules/
│   ├── _core/                # Core infrastructure
│   │   ├── registry.nix      # Module registry builder
│   │   └── user.nix          # hostUsers option & home-manager setup
│   ├── home/                 # User modules (auto-discovered, hierarchical enables)
│   │   ├── browsers/         # chromium, vivaldi
│   │   ├── cli/              # htop, shell-utils
│   │   ├── desktop/          # hyprland, awesomewm, appearance, services, widgets
│   │   ├── editors/          # cursor, neovim (nixvim)
│   │   ├── games/            # steam
│   │   ├── media/            # vlc, spotify
│   │   ├── messengers/       # telegram
│   │   ├── security/         # keepassxc, bitwarden
│   │   ├── shell/            # zsh, tmux
│   │   └── terminal/         # ghostty
│   └── systems/              # System modules (manual import)
│       ├── all/              # Cross-platform (fonts, nix settings, git, ssh)
│       ├── linux/            # NixOS-only (nvidia, sound, networking, keyboards)
│       └── darwin/           # macOS-only (homebrew, macos-settings)
├── overlays/                 # Nixpkgs overlays
├── pkgs/                     # Custom packages
└── templates/                # Flake templates
```

## Module System

### Two module types

| Type | Location | Created with | Enabled via | Auto-discovered |
|------|----------|-------------|-------------|-----------------|
| User | `modules/home/` | `mkModuleV2` | `hostUsers.<user>.modules.<path>.enable` | Yes |
| System | `modules/systems/` | `mkSystemModuleV2` | `systemAll.*` / `systemLinux.*` / `systemDarwin.*` | No (needs import) |

### Hierarchical enables

Module enabled if ANY of these is true:
- `modules.home.browsers.vivaldi.enable = true` (specific)
- `modules.home.browsers.enable = true` (category)
- `modules.home.enable = true` (all home)
- `hostUsers.<user>.modules.home.browsers.enable = true` (per-user)

Path follows directory structure: `modules/home/<category>/<module>` → `modules.home.<category>.<module>`

### Platform sections in modules

```nix
module = {
  allSystems.home.packages = [ ... ];      # Both platforms
  nixosSystems.home.packages = [ ... ];    # Linux only
  darwinSystems.homebrew.casks = [ ... ];  # macOS only
};

systemModule = {
  nixosSystems = { programs.hyprland.enable = true; };
  darwinSystems = { ... };
  allSystems = { ... };
};
```

Home-manager attrs (`home`, `programs`, `xdg`, `services`, etc.) are automatically routed to all enabled `hostUsers`.

## Key Helpers (lib/default.nix)

- `lib.my.mkModuleV2 args { module, systemModule?, dotfiles?, imports?, extraOptions?, ... }` — User modules
- `lib.my.mkSystemModuleV2 args { namespace, module, moduleLinux?, moduleDarwin?, ... }` — System modules
- `lib.my.shouldEnableModule { config, modulePath }` — Check hierarchical enable
- `lib.my.getUsersWithModule { config, modulePath }` — Users with module enabled
- `lib.my.getUsersWithModuleNames { config, _modulePath }` — Usernames list
- `lib.my.mkDotfilesSymlink { config, self, path, source, target? }` — Live-editable dotfile symlinks
- `lib.my.mkUsersAttrs usernames fn` — Creates `users.users` attrset
- `lib.my.mkModule system config cfg` — Low-level platform-aware config builder
- `lib.my.getTheme config` — Get active theme (set via `config.theme.name`)

## Live-Editable Dotfiles

Store config files in `<module>/dotfiles/`, symlinked to `~/.config/<app>`:
```
modules/home/terminal/ghostty/
├── ghostty.nix
└── dotfiles/
    ├── config
    └── themes/catppuccin-mocha
```
Changes apply immediately without `nixos-rebuild`.

Requires `DOTFILES_DIR` environment variable set in host config.

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
| `nix-oldstar` | NixOS | Remote, vantage override |
| `mac-brightstar` | Darwin | MacBook, nix-homebrew |
