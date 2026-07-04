-- LazyVim-equivalent vim options
local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Tabs & indentation
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
opt.shiftround = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Appearance
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 4
opt.sidescrolloff = 8
opt.wrap = false
opt.showmode = false -- statusline handles this

-- Windows
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"

-- Clipboard
opt.clipboard = "unnamedplus"

-- Undo
opt.undofile = true
opt.undolevels = 10000

-- Behavior
opt.timeoutlen = 300
opt.updatetime = 200
opt.completeopt = "menu,menuone,noselect"
opt.wildmode = "longest:full,full"
opt.mouse = "a"
opt.confirm = true -- confirm to save changes before closing buffer

-- Fill chars
opt.fillchars = {
  diff = "╱",
  eob = " ",
}

-- Grep (use ripgrep)
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"

-- Sessions
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }

-- Spelling
opt.spelllang = { "en" }
