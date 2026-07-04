-- LSP configuration (Neovim 0.11+ native API)
-- Servers are installed via Nix (runtimePkgs in plugins.nix)
-- Uses vim.lsp.config / vim.lsp.enable instead of deprecated lspconfig framework

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

-- Common LSP keymaps (attached via LspAttach autocmd)
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_keymaps", { clear = true }),
  callback = function(event)
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, desc = desc })
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
    map("n", "<leader>cl", "<cmd>checkhealth lsp<cr>", "LSP info")
  end,
})

-- Capabilities (with blink.cmp completion support)
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, blink = pcall(require, "blink.cmp")
if ok then
  capabilities = blink.get_lsp_capabilities(capabilities)
end

-- ── Server configurations ──────────────────────────────────────────────────

-- C/C++ (clangd)
vim.lsp.config("clangd", {
  cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
  capabilities = capabilities,
})

-- Python
vim.lsp.config("pyright", {
  capabilities = capabilities,
})

-- Nix
vim.lsp.config("nil_ls", {
  capabilities = capabilities,
  settings = {
    ["nil"] = {
      formatting = { command = { "nixpkgs-fmt" } },
    },
  },
})

-- Bash
vim.lsp.config("bashls", {
  capabilities = capabilities,
})

-- Lua
vim.lsp.config("lua_ls", {
  capabilities = capabilities,
  settings = {
    Lua = {
      workspace = { checkThirdParty = false },
      codeLens = { enable = true },
      completion = { callSnippet = "Replace" },
      diagnostics = { globals = { "vim" } },
    },
  },
})

-- Rust
vim.lsp.config("rust_analyzer", {
  capabilities = capabilities,
  settings = {
    ["rust-analyzer"] = {
      checkOnSave = { command = "clippy" },
    },
  },
})

-- Go
vim.lsp.config("gopls", {
  capabilities = capabilities,
  settings = {
    gopls = {
      gofumpt = true,
      analyses = { unusedparams = true },
      staticcheck = true,
    },
  },
})

-- TypeScript
vim.lsp.config("ts_ls", {
  capabilities = capabilities,
})

-- Enable all configured servers
vim.lsp.enable({
  "clangd",
  "pyright",
  "nil_ls",
  "bashls",
  "lua_ls",
  "rust_analyzer",
  "gopls",
  "ts_ls",
})
