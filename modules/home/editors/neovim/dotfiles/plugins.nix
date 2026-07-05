# nix-wrapper-modules Neovim configuration
# Declares plugins (specs) and runtime packages (LSPs, formatters, linters).
# The actual plugin configuration lives in Lua files under dotfiles/nvim/lua/
#
# To add/remove plugins or LSP servers: edit this file → nixos-rebuild switch
# To change keymaps, options, plugin config: edit Lua files → restart nvim
{ pkgs, lib }:
{

  # ── UI Plugins ─────────────────────────────────────────────────────────────

  specs.ui = with pkgs.vimPlugins; [
    tokyonight-nvim # colorscheme
    lualine-nvim # statusline
    bufferline-nvim # buffer/tab bar
    nvim-web-devicons # file icons (nerd font)
    noice-nvim # cmdline, messages, popupmenu UI
    nui-nvim # UI component library (noice dep)
    nvim-notify # notification manager
    snacks-nvim # dashboard, indent guides, git browse, etc.
    which-key-nvim # keybinding popup hints
    dressing-nvim # improved vim.ui.select / vim.ui.input
  ];

  # ── Editor Plugins ─────────────────────────────────────────────────────────

  specs.editor = with pkgs.vimPlugins; [
    neo-tree-nvim # file explorer sidebar
    telescope-nvim # fuzzy finder
    telescope-fzf-native-nvim # native fzf sorter for telescope
    gitsigns-nvim # git change indicators in sign column
    trouble-nvim # diagnostics / quickfix list
    todo-comments-nvim # highlight TODO/FIXME/HACK/NOTE
    flash-nvim # motion / jump plugin
  ];

  # ── Coding Plugins ─────────────────────────────────────────────────────────

  specs.coding = with pkgs.vimPlugins; [
    (nvim-treesitter.withAllGrammars) # syntax highlighting + text objects
    nvim-lspconfig # LSP server configuration
    blink-cmp # autocompletion engine
    conform-nvim # formatting on save
    nvim-lint # async linting
    mini-nvim # mini.pairs, mini.surround, mini.ai, etc.
    luasnip # snippet engine
  ];

  # ── Dependency Plugins ─────────────────────────────────────────────────────

  specs.deps = with pkgs.vimPlugins; [
    plenary-nvim # utility library (telescope, gitsigns dep)
  ];

  # ── Runtime Packages ───────────────────────────────────────────────────────
  # These are added to Neovim's $PATH (not installed globally).
  # Neovim's LSP, formatters, and linters will find them automatically.

  runtimePkgs = with pkgs; [
    # ── LSP servers ──
    clang-tools # C/C++ (clangd + clang-format)
    pyright # Python
    nil # Nix
    bash-language-server # Bash
    lua-language-server # Lua
    rust-analyzer # Rust
    gopls # Go
    typescript-language-server # TypeScript

    # ── Formatters ──
    stylua # Lua
    nixpkgs-fmt # Nix
    black # Python
    gofumpt # Go
    prettier # TS/JS/HTML/CSS

    # ── Linters ──
    shellcheck # Bash/Shell

    # ── Tools ──
    ripgrep # fast grep (telescope backend)
    fd # fast find (telescope backend)
    tree-sitter # tree-sitter CLI (grammar compilation)
  ];
}
