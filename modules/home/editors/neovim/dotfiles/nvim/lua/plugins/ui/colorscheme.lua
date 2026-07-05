-- Colorscheme: tokyonight (LazyVim default)
require("tokyonight").setup({
  style = "moon",
  transparent = false,
  terminal_colors = true,
  styles = {
    comments = { italic = true },
    keywords = { italic = true },
    sidebars = "dark",
    floats = "dark",
  },
})

vim.cmd.colorscheme("tokyonight")

-- Make window split borders brighter
vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#7aa2f7", bold = true })
