---
name: dotfiles-management
description: Managing live-editable dotfiles with mkDotfilesSymlink and dotfiles/ directories
---

# Dotfiles Management

## Concept

Dotfiles are config files stored in the repo and **symlinked** to their expected locations (e.g., `~/.config/<app>`). Changes to these files apply immediately — no `nixos-rebuild` needed.

## Directory Convention

```
modules/home/<category>/<app>/
├── <app>.nix          # Module definition
└── dotfiles/          # Config files (symlinked)
    ├── config
    └── themes/
        └── catppuccin-mocha
```

## API: mkDotfilesSymlink

```nix
lib.my.mkDotfilesSymlink {
  inherit config self;
  path = "ghostty";                                    # Target: ~/.config/ghostty
  source = "modules/home/terminal/ghostty/dotfiles";  # Source in repo
  # target = "~/.config/ghostty";                     # Optional: explicit target path
}
```

- Default target: `~/.config/${path}`
- Custom target: set `target` explicitly (e.g., `"~/.tmux"`)
- Requires `DOTFILES_DIR` env variable in host config

## Using in mkModuleV2

Preferred way — use the `dotfiles` parameter:

```nix
lib.my.mkModuleV2 args {
  description = "Ghostty terminal";

  module = {
    allSystems.home.packages = [ pkgs.ghostty ];
  };

  dotfiles = {
    path = "ghostty";
    source = "modules/home/terminal/ghostty/dotfiles";
    # target = "~/.config/ghostty";  # optional, defaults to ~/.config/${path}
  };
}
```

## Custom Target Paths

For configs that live outside `~/.config/`:

```nix
dotfiles = {
  path = "tmux";
  source = "modules/home/shell/tmux/dotfiles";
  target = "~/.tmux";  # → symlinks to ~/.tmux instead of ~/.config/tmux
};
```

## How It Works

1. `mkDotfilesSymlink` reads `DOTFILES_DIR` from host config
2. Constructs full source path: `${DOTFILES_DIR}/${source}`
3. Creates `xdg.configFile` (for `~/.config/`) or `home.file` (for other paths) via `mkOutOfStoreSymlink`
4. Symlink created for all enabled `hostUsers`

## DOTFILES_DIR

Must be set in each host config:
```nix
environment.variables.DOTFILES_DIR = "/home/dgarifullin/Workspaces/gdr/dot";
```

Without it, `mkDotfilesSymlink` throws an error.

## Adding Dotfiles to an Existing Module

1. Create `dotfiles/` directory next to the module `.nix` file
2. Put config files inside
3. Add `dotfiles` parameter to `mkModuleV2` call
4. No rebuild needed for future config edits — just edit files in `dotfiles/`
