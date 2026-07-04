-- LazyVim-like Neovim configuration
-- Plugins are pre-installed by Nix (nix-wrapper-modules)
-- Edit these Lua files and restart nvim — no nixos-rebuild needed!
--
-- Phase 3 will populate this with full config:
--   lua/config/options.lua   — vim.opt settings
--   lua/config/keymaps.lua   — keybindings
--   lua/config/autocmds.lua  — autocommands
--   lua/plugins/             — plugin setup() calls

-- For now, just set the leader key and enable basic settings
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Enable the byte-compiled loader for faster startup
vim.loader.enable()

print("✅ Neovim loaded — nix-wrapper-modules working! Phase 3 will add full config.")
