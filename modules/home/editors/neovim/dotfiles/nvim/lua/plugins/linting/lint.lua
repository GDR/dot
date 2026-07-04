-- Linting (nvim-lint)
-- Linters are installed via Nix (runtimePkgs in plugins.nix)
require("lint").linters_by_ft = {
  sh = { "shellcheck" },
  bash = { "shellcheck" },
}

-- Auto-lint on save and text change
vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
  group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
  callback = function()
    require("lint").try_lint()
  end,
})
