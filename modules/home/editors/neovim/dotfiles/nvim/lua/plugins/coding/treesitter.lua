-- Treesitter — syntax highlighting, text objects, indent
-- Grammars are pre-installed by Nix (withAllGrammars in plugins.nix)
-- No need for nvim-treesitter.configs — use built-in Neovim treesitter APIs

-- Enable treesitter highlighting for all supported filetypes
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

-- Enable treesitter-based indentation
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldenable = false -- don't fold by default
vim.opt.foldlevel = 99

-- Incremental selection via nvim-treesitter (if available)
local ok, configs = pcall(require, "nvim-treesitter.configs")
if ok then
  configs.setup({
    highlight = { enable = true },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "<C-space>",
        node_incremental = "<C-space>",
        scope_incremental = false,
        node_decremental = "<bs>",
      },
    },
  })
end
