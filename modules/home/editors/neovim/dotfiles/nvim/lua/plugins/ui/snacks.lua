-- Snacks.nvim — dashboard, indent guides, notifications, etc.
require("snacks").setup({
  dashboard = {
    enabled = true,
    -- Override sections to remove "startup" (requires lazy.nvim)
    sections = {
      { section = "header" },
      { section = "keys", gap = 1, padding = 1 },
    },
    preset = {
      header = [[
 ███╗   ██╗██╗██╗  ██╗██╗   ██╗██╗███╗   ███╗
 ████╗  ██║██║╚██╗██╔╝██║   ██║██║████╗ ████║
 ██╔██╗ ██║██║ ╚███╔╝ ╚██╗ ██╔╝██║██╔████╔██║
 ██║╚██╗██║██║ ██╔██╗  ╚████╔╝ ██║██║╚██╔╝██║
 ██║ ╚████║██║██╔╝ ██╗  ╚██╔╝  ██║██║ ╚═╝ ██║
 ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝╚═╝     ╚═╝]],
      keys = {
        { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
        { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
        { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
        { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
        { icon = "󰒲 ", key = "q", desc = "Quit", action = ":qa" },
      },
    },
  },
  indent = { enabled = true },
  input = { enabled = true },
  notifier = { enabled = true },
  scope = { enabled = true },
  scroll = { enabled = true },
  statuscolumn = { enabled = true },
  words = { enabled = true },
})
