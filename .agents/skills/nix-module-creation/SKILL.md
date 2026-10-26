---
name: nix-module-creation
description: Creating new NixOS user features and system modules using mkFeature/mkSystemModuleV2
---

# Creating NixOS Modules and Features

## User Feature (mkFeature)

### Simple feature

```nix
# modules/home/<category>/<name>.nix
{ lib, pkgs, ... }:

lib.my.mkFeature {
  description = "Description of the feature";
  platforms = [ "linux" "darwin" ];  # optional, defaults to both

  homeModule = { pkgs, ... }: {
    home.packages = [ pkgs.my-tool ];
  };
  # Or platform-specific:
  # homeModuleLinux = { pkgs, ... }: { home.packages = [ pkgs.linux-tool ]; };
  # darwinModule = { homebrew.casks = [ "mac-tool" ]; };
}
```

### With dotfiles (live-editable symlinks)

```nix
# modules/home/<category>/<name>/<name>.nix
{ lib, pkgs, ... }:

lib.my.mkFeature {
  description = "Tool with live-editable config";

  homeModule = { pkgs, ... }: {
    home.packages = [ pkgs.my-tool ];
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
{ lib, pkgs, ... }:

lib.my.mkFeature {
  description = "Feature with system-level configuration";

  nixosModule = { ... }: {
    programs.hyprland.enable = true;
    services.greetd.enable = true;
  };

  homeModuleLinux = { pkgs, ... }: {
    home.packages = [ pkgs.hyprland ];
  };

  dotfiles = {
    path = "hyprland";
    source = "modules/home/desktop/hyprland/dotfiles";
  };
}
```

### With custom options (`homeOptions` / `systemOptions`)

```nix
{ lib, ... }:

lib.my.mkFeature {
  description = "Feature with custom per-user and system options";

  homeOptions = {
    showHostname = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Show hostname in prompt";
    };
  };

  systemOptions = {
    openFirewall = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = "Open firewall ports at system level";
    };
  };

  homeModule = { pkgs, featureCfg, ... }: {
    home.packages = [ pkgs.my-tool ];
    # Access per-user option: featureCfg.showHostname
  };

  nixosModule = { featureCfg, ... }: {
    # Access system option: featureCfg.openFirewall
  };
}
```

### With dependencies (requires / recommends)

```nix
{ lib, ... }:

lib.my.mkFeature {
  description = "Feature with dependencies";

  requires = [
    "home.shell.zsh"
    "home.desktop.services.audio"
  ];
  recommends = [
    "home.cli.htop"
  ];

  homeModule = { pkgs, ... }: {
    home.packages = [ pkgs.my-tool ];
  };
}
```

## mkFeature Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `description` | string | No | Feature description |
| `platforms` | list | No | `["linux" "darwin"]` (default: both) |
| `requires` | list | No | Hard feature path dependencies (cannot be disabled while parent is enabled) |
| `recommends` | list | No | Soft feature path dependencies (overridable by `enable = false`) |
| `homeOptions` | attrset | No | Per-user typed Home Manager options under `hostUsers.<user>.modules` |
| `systemOptions` | attrset | No | System-wide typed options under `modules.home` |
| `dotfiles` | `{ path, source, target?, live? }` | No | Live-editable symlinks |
| `homeModule` | function or attrset | No | Home Manager config for users enabling the feature |
| `homeModuleLinux` | function or attrset | No | Linux-only Home Manager config |
| `homeModuleDarwin` | function or attrset | No | Darwin-only Home Manager config |
| `nixosModule` | function or attrset | No | System-level NixOS config when any user enables the feature |
| `darwinModule` | function or attrset | No | System-level Darwin config when any user enables the feature |

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
}
```

Enable: `modules.system.linux.<category>.<name>.enable = true` in host config.

## Checklist

1. Decide scope: System (`systems/*`) or User (`home/*`)
2. Choose/create category subdirectory
3. Create module file using templates above
4. **System modules only**: Auto-discovered or added under `modules/systems/{all,linux,darwin}`
5. **User features**: Auto-discovered — just add enable path to `hostUsers.<user>.modules`
6. `git add` new files before `nix flake check`
7. Test: `nix flake check`
