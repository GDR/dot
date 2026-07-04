-- Fuzzy finder
local telescope = require("telescope")
local actions = require("telescope.actions")

telescope.setup({
  defaults = {
    prompt_prefix = " ",
    selection_caret = " ",
    mappings = {
      i = {
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-n>"] = actions.cycle_history_next,
        ["<C-p>"] = actions.cycle_history_prev,
        ["<esc>"] = actions.close,
      },
    },
  },
})

-- Load fzf native extension
pcall(telescope.load_extension, "fzf")

-- Keymaps
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
vim.keymap.set("n", "<leader>fc", builtin.git_commits, { desc = "Git commits" })
vim.keymap.set("n", "<leader>fs", builtin.git_status, { desc = "Git status" })
vim.keymap.set("n", "<leader>/", builtin.live_grep, { desc = "Grep (root)" })
vim.keymap.set("n", "<leader><space>", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "Word under cursor" })
vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "Keymaps" })
