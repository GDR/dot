-- Highlight TODO/FIXME/HACK/NOTE comments
require("todo-comments").setup({})

vim.keymap.set("n", "]t", function() require("todo-comments").jump_next() end, { desc = "Next TODO" })
vim.keymap.set("n", "[t", function() require("todo-comments").jump_prev() end, { desc = "Prev TODO" })
vim.keymap.set("n", "<leader>xt", "<cmd>Trouble todo toggle<cr>", { desc = "TODOs (Trouble)" })
vim.keymap.set("n", "<leader>st", "<cmd>TodoTelescope<cr>", { desc = "TODOs (Telescope)" })
