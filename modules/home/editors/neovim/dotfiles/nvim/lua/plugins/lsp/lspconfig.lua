-- LSP configuration
-- Servers are installed via Nix (runtimePkgs in plugins.nix)
-- This file configures how they attach and their keymaps/settings

local lspconfig = require("lspconfig")

-- Diagnostic appearance
vim.diagnostic.config({
  underline = true,
  update_in_insert = false,
  virtual_text = {
    spacing = 4,
    source = "if_many",
    prefix = "●",
  },
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.HINT] = " ",
      [vim.diagnostic.severity.INFO] = " ",
    },
  },
})

-- Common on_attach: keymaps for all LSP servers
local on_attach = function(_, bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end
  map("n", "gd", vim.lsp.buf.definition, "Go to definition")
  map("n", "gr", vim.lsp.buf.references, "References")
  map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
  map("n", "gI", vim.lsp.buf.implementation, "Go to implementation")
  map("n", "gy", vim.lsp.buf.type_definition, "Go to type definition")
  map("n", "K", vim.lsp.buf.hover, "Hover")
  map("n", "gK", vim.lsp.buf.signature_help, "Signature help")
  map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature help")
  map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
  map("n", "<leader>cr", vim.lsp.buf.rename, "Rename")
  map("n", "<leader>cl", "<cmd>LspInfo<cr>", "LSP info")
end

-- Capabilities (with blink.cmp completion support)
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, blink = pcall(require, "blink.cmp")
if ok then
  capabilities = blink.get_lsp_capabilities(capabilities)
end

local defaults = { on_attach = on_attach, capabilities = capabilities }

-- ── Server configurations ──────────────────────────────────────────────────

-- C/C++ (clangd)
lspconfig.clangd.setup(vim.tbl_extend("force", defaults, {
  cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
}))

-- Python
lspconfig.pyright.setup(defaults)

-- Nix
lspconfig.nil_ls.setup(vim.tbl_extend("force", defaults, {
  settings = {
    ["nil"] = {
      formatting = { command = { "nixpkgs-fmt" } },
    },
  },
}))

-- Bash
lspconfig.bashls.setup(defaults)

-- Lua
lspconfig.lua_ls.setup(vim.tbl_extend("force", defaults, {
  settings = {
    Lua = {
      workspace = { checkThirdParty = false },
      codeLens = { enable = true },
      completion = { callSnippet = "Replace" },
      diagnostics = { globals = { "vim" } },
    },
  },
}))

-- Rust
lspconfig.rust_analyzer.setup(vim.tbl_extend("force", defaults, {
  settings = {
    ["rust-analyzer"] = {
      checkOnSave = { command = "clippy" },
    },
  },
}))

-- Go
lspconfig.gopls.setup(vim.tbl_extend("force", defaults, {
  settings = {
    gopls = {
      gofumpt = true,
      analyses = { unusedparams = true },
      staticcheck = true,
    },
  },
}))

-- TypeScript
lspconfig.ts_ls.setup(defaults)
