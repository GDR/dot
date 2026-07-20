-- ╭──────────────────────────────────────────────────────────╮
-- │  LazyVim-like Neovim Configuration                      │
-- │  Plugins are pre-installed by Nix (nix-wrapper-modules) │
-- │  Edit these Lua files → restart nvim — no rebuild!      │
-- ╰──────────────────────────────────────────────────────────╯

-- Leader key must be set before any plugin loads
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Headless checks use this state because Neovim may exit successfully even when
-- an init file raises an error.
vim.g.dotfiles_config_status = "loading"
vim.g.dotfiles_config_errors = {}

-- Enable byte-compiled loader for faster startup
vim.loader.enable()

-- Load core configuration
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Auto-load all plugin configs from lua/plugins/**/*.lua
local plugin_config_errors = {}

local function load_plugin_configs(base_dir)
  local config_path = vim.fn.stdpath("config") .. "/lua/" .. base_dir
  if vim.fn.isdirectory(config_path) == 0 then
    return
  end

  for _, file in ipairs(vim.fn.glob(config_path .. "/**/*.lua", false, true)) do
    local module = file:match("lua/(.+)%.lua$"):gsub("/", ".")
    local ok, err = pcall(require, module)
    if not ok then
      local message = "Error loading " .. module .. ":\n" .. err
      table.insert(plugin_config_errors, message)
      vim.notify(message, vim.log.levels.ERROR)
    end
  end
end

load_plugin_configs("plugins")

vim.g.dotfiles_config_errors = plugin_config_errors
vim.g.dotfiles_config_status = #plugin_config_errors == 0 and "ok" or "failed"
