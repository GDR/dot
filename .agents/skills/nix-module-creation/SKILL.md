---
name: nix-module-creation
description: Creating new NixOS user and system modules using mkModuleV2/mkSystemModuleV2
---

# Creating NixOS Modules

## User Module (mkModuleV2)

### Simple module

```nix
# modules/home/<category>/<name>.nix
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  description = "Description of the module";
  platforms = [ "linux" "darwin" ];  # optional, defaults to both

  module = {
    allSystems.home.packages = [ pkgs.my-tool ];
    # Or platform-specific:
    # nixosSystems.home.packages = [ pkgs.linux-tool ];
    # darwinSystems.homebrew.casks = [ "mac-tool" ];
  };
}
```

### With dotfiles (live-editable symlinks)

```nix
# modules/home/<category>/<name>/<name>.nix
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  description = "Tool with live-editable config";

  module = {
    allSystems.home.packages = [ pkgs.my-tool ];
  };

  dotfiles = {
    path = "my-tool";           # → ~/.config/my-tool
    source = "modules/home/<category>/<name>/dotfiles";
  };
}
```

Directory layout:
```
modules/home/<category>/<name>/
├── <name>.nix
└── dotfiles/
    └── config
```

### With system-level config

```nix
{ lib, pkgs, config, ... }@args:

lib.my.mkModuleV2 args {
  description = "Module with system-level configuration";

  systemModule = {
    nixosSystems = {
      programs.hyprland.enable = true;
      services.greetd.enable = true;
    };
  };

  module = {
    nixosSystems.home.packages = [ pkgs.hyprland ];
  };

  dotfiles = {
    path = "hyprland";
    source = "modules/home/desktop/hyprland/dotfiles";
  };
}
```

### With custom options

```nix
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  description = "Module with custom options";

  extraOptions = {
    showHostname = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Show hostname in prompt";
    };
  };

  # When using extraOptions, module becomes a function receiving cfg
  module = cfg: {
    allSystems.home.packages = [ pkgs.my-tool ];
    # Access option: cfg.showHostname
  };
}
```

### With imports (sub-modules)

```nix
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  description = "Module with sub-module imports";

  imports = [
    ./dotfiles/general.nix
    ./dotfiles/plugins/airline.nix
  ];

  systemModule = {
    allSystems.programs.nixvim.enable = true;
  };

  module = {
    allSystems.home.packages = [ pkgs.ripgrep pkgs.fzf ];
  };
}
```

## mkModuleV2 Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `description` | string | No | Module description |
| `platforms` | list | No | `["linux" "darwin"]` (default: both) |
| `requires` | list | No | Module path dependencies |
| `module` | attrset or `cfg -> attrset` | No | Platform config with `allSystems`/`nixosSystems`/`darwinSystems` sections |
| `systemModule` | attrset or `cfg -> attrset` | No | System-level config (same sections) |
| `dotfiles` | `{ path, source, target? }` | No | Live-editable symlinks |
| `extraOptions` | attrset | No | Additional NixOS options (merged with `enable`) |
| `imports` | list | No | Sub-module imports |

## System Module (mkSystemModuleV2)

```nix
# modules/systems/{all,linux,darwin}/<category>/<name>.nix
{ lib, pkgs, config, ... }@args:

lib.my.mkSystemModuleV2 args {
  namespace = "linux";  # "all" | "linux" | "darwin"
  description = "My system service";

  module = cfg: {
    services.my-service.enable = true;
  };

  # For namespace = "all", optional platform-specific additions:
  # moduleLinux = cfg: { ... };
  # moduleDarwin = cfg: { ... };

  extraOptions = {
    open = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };
  };
}
```

Enable: `systemLinux.<category>.<name>.enable = true` in host config.

## Checklist

1. Decide scope: System (`systems/*`) or User (`home/*`)
2. Choose/create category subdirectory
3. Create module file using templates above
4. **System modules only**: Add import to `systems/*/default.nix`
5. **User modules**: Auto-discovered — just add enable path to `hostUsers.<user>.modules`
6. `git add` new files before `nix flake check`
7. Test: `nix flake check`
