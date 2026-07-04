-- Keybinding popup hints
require("which-key").setup({
  plugins = { spelling = true },
})

-- Register group labels
require("which-key").add({
  { "<leader>b", group = "buffers" },
  { "<leader>c", group = "code" },
  { "<leader>f", group = "file/find" },
  { "<leader>g", group = "git" },
  { "<leader>gh", group = "git hunks" },
  { "<leader>s", group = "search" },
  { "<leader>u", group = "ui" },
  { "<leader>x", group = "diagnostics" },
})
