---
name: dotfiles-management
description: Managing live-editable and store-immutable dotfiles with mkFeature and dotfiles/ directories
---

# Dotfiles Management

## Concept

Dotfiles are config files stored inside a feature's `dotfiles/` directory and symlinked via `mkFeature`. Changes in **live mode** (`dotfiles.live = true` or `dotfilesLive = true`) apply immediately without rebuilding; **store mode** (`live = false`, the default) symlinks `/nix/store` copies for generation-safe rollbacks.

## Directory Convention

```
modules/home/<category>/<app>/
├── <app>.nix          # Feature definition (mkFeature)
└── dotfiles/          # Config files (symlinked)
    ├── config
    └── themes/
        └── catppuccin-mocha
```

## Using `dotfiles` in `mkFeature`

```nix
# modules/home/terminal/ghostty/ghostty.nix
{ lib, ... }:

lib.my.mkFeature {
  description = "Ghostty terminal";

  homeModule = { pkgs, ... }: {
    home.packages = [ pkgs.ghostty ];
  };

  dotfiles = {
    path = "ghostty";                                   # Target: ~/.config/ghostty
    source = "modules/home/terminal/ghostty/dotfiles";  # Source in repo
    # target = "~/.config/ghostty";                     # Optional: explicit target path
    # live = true;                                      # Optional: per-feature default override
  };
}
```

- Default target: `~/.config/${path}` (mapped to `xdg.configFile`).
- Custom target outside `~/.config/` (e.g., `target = "~/.tmux"`): mapped to `home.file`.

## Live vs. Nix Store Symlink Modes

Resolution order (most specific wins):
1. Per-user or global feature toggle: `hostUsers.<user>.modules.home.<cat>.<mod>.dotfilesLive = true;` or `modules.home.<cat>.<mod>.dotfilesLive = true;`
2. Feature descriptor default: `dotfiles.live = true;`
3. Host-wide toggle: `dotfiles.live = true;` (defaults to `false`)

## `DOTFILES_DIR`

Set in each host config (`default.nix`) when live editing is used:
```nix
environment.variables.DOTFILES_DIR = "/home/dgarifullin/Workspaces/gdr/dot";
```
When unset, `compileUserDotfiles` falls back to `~/dot`.

## Adding Dotfiles to an Existing Feature

1. Move `<app>.nix` into `modules/home/<category>/<app>/<app>.nix` if it isn't already a directory.
2. Create `dotfiles/` next to `<app>.nix` and put config files inside.
3. Add `dotfiles = { path = "..."; source = "modules/home/<category>/<app>/dotfiles"; };` to `mkFeature`.
4. `git add` the new files, then rebuild; once `dotfilesLive = true` (or `dotfiles.live = true`) is active, edits inside `dotfiles/` apply without rebuilding.
