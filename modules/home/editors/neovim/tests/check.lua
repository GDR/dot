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
  "rg",
  "fd",
}

local missing = {}
for _, executable in ipairs(executables) do
  if vim.fn.executable(executable) ~= 1 then
    table.insert(missing, executable)
  end
end

if #missing > 0 then
  io.stderr:write("Missing Neovim runtime executables: " .. table.concat(missing, ", ") .. "\n")
  vim.cmd("cquit 1")
end

vim.cmd("qa")
