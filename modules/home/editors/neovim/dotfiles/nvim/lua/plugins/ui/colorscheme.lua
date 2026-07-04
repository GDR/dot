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
