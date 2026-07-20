local failures = {}

if vim.g.dotfiles_config_status ~= "ok" then
  table.insert(failures, "Neovim configuration status: " .. tostring(vim.g.dotfiles_config_status))
  for _, err in ipairs(vim.g.dotfiles_config_errors or {}) do
    table.insert(failures, err)
  end
end

local executables = {
  -- LSP servers
  "clangd",
  "pyright-langserver",
  "nil",
  "bash-language-server",
  "lua-language-server",
  "rust-analyzer",
  "gopls",
  "typescript-language-server",

  -- Formatters
  "stylua",
  "nixpkgs-fmt",
  "black",
  "gofumpt",
  "prettier",
  "clang-format",
  "rustfmt",
  "shfmt",

  -- Linters and search tools
  "shellcheck",
  "git",
  "rg",
  "fd",
}

for _, executable in ipairs(executables) do
  if vim.fn.executable(executable) ~= 1 then
    table.insert(failures, "Missing runtime executable: " .. executable)
  end
end

if #failures > 0 then
  io.stderr:write(table.concat(failures, "\n") .. "\n")
  vim.cmd("cquit 1")
end

vim.cmd("qa")
