-- LazyVim-style keymaps
local map = vim.keymap.set

-- ── Window navigation ──
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- ── Resize windows ──
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- ── Buffer navigation ──
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bd", function() Snacks.bufdelete() end, { desc = "Close buffer" })
map("n", "<leader>bD", "<cmd>bdelete!<cr>", { desc = "Close buffer (force)" })

-- ── Move lines ──
map("n", "<A-j>", "<cmd>move .+1<cr>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>move .-2<cr>==", { desc = "Move line up" })
map("v", "<A-j>", ":move '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":move '<-2<cr>gv=gv", { desc = "Move selection up" })
map("i", "<A-j>", "<esc><cmd>move .+1<cr>==gi", { desc = "Move line down" })
map("i", "<A-k>", "<esc><cmd>move .-2<cr>==gi", { desc = "Move line up" })

-- ── Save / Quit ──
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
map("n", "<leader>Q", "<cmd>qa<cr>", { desc = "Quit all" })

-- ── Clear search highlight ──
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })
map("n", "<leader>ur", "<cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><cr>", { desc = "Redraw / clear hlsearch" })

-- ── Better indenting (stay in visual mode) ──
map("v", "<", "<gv")
map("v", ">", ">gv")

-- ── New file ──
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New file" })

-- ── Diagnostics ──
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })

-- ── Terminal ──
map("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Enter Normal Mode" })

-- ── Misc ──
map("n", "<leader>R", function()
  vim.cmd("restart")
end, { desc = "Restart Neovim" })
