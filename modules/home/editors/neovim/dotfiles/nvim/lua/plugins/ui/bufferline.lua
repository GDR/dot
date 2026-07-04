-- Buffer/tab bar
require("bufferline").setup({
  options = {
    close_command = "bdelete! %d",
    diagnostics = "nvim_lsp",
    always_show_bufferline = false,
    offsets = {
      {
        filetype = "neo-tree",
        text = "Neo-tree",
        highlight = "Directory",
        text_align = "left",
      },
    },
  },
})
