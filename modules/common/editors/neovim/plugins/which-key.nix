{ ... }:
let
  icons = {
    ActiveLSP = "";
    ActiveTS = "";
    ArrowLeft = "";
    ArrowRight = "";
    Bookmarks = "";
    BufferClose = "󰅖";
    DapBreakpoint = "";
    DapBreakpointCondition = "";
    DapBreakpointRejected = "";
    DapLogPoint = "󰛿";
    DapStopped = "󰁕";
    Debugger = "";
    DefaultFile = "󰈙";
    Diagnostic = "󰒡";
    DiagnosticError = "";
    DiagnosticHint = "󰌵";
    DiagnosticInfo = "󰋼";
    DiagnosticWarn = "";
    Ellipsis = "…";
    Environment = "";
    FileNew = "";
    FileModified = "";
    FileReadOnly = "";
    FoldClosed = "";
    FoldOpened = "";
    FoldSeparator = " ";
    FolderClosed = "";
    FolderEmpty = "";
    FolderOpen = "";
    Git = "󰊢";
    GitAdd = "";
    GitBranch = "";
    GitChange = "";
    GitConflict = "";
    GitDelete = "";
    GitIgnored = "◌";
    GitRenamed = "➜";
    GitSign = "▎";
    GitStaged = "✓";
    GitUnstaged = "✗";
    GitUntracked = "★";
    LSPLoading1 = "";
    LSPLoading2 = "󰀚";
    LSPLoading3 = "";
    MacroRecording = "";
    Package = "󰏖";
    Paste = "󰅌";
    Refresh = "";
    Search = "";
    Selected = "❯";
    Session = "󱂬";
    Sort = "󰒺";
    Spellcheck = "󰓆";
    Tab = "󰓩";
    TabClose = "󰅙";
    Terminal = "";
    Window = "";
    WordFile = "󰈭";
  };
in
{
  config.programs.nixvim = {
    plugins = {
      which-key = {
        enable = true;
        icons.group = "";
        window.border = "single";

        # Disable which-key when in neo-tree or telescope
        disable.filetypes = [
          "TelescopePrompt"
          "neo-tree"
          "neo-tree-popup"
        ];

        # Customize section names (prefixed mappings)
        registrations = {
          "<leader>b".name = "${icons.Tab} Buffers";
          "<leader>bs".name = "${icons.Sort} Sort Buffers";
          "<leader>d".name = "${icons.Debugger} Debugger";
          "<leader>f".name = "${icons.Search} Find";
          "<leader>g".name = "${icons.Git} Git";
          "<leader>l".name = "${icons.ActiveLSP} Language Tools";
          "<leader>m".name = " Markdown";
          "<leader>s".name = "${icons.Session} Session";
          "<leader>t".name = "${icons.Terminal} Terminal";
          "<leader>u".name = "${icons.Window} UI/UX";
        };
      };
    };
  };
}
