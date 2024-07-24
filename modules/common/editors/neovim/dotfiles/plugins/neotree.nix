{ ... }:
let
in {
  config.programs.nixvim = {
    plugins = {
      neo-tree = {
        enable = true;
      };
    };
    keymaps = [
      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>Neotree toggle<cr>";
        options.desc = "Toggle explorer";
      }
      {
        mode = "n";
        key = "<leader>o";
        options.desc = "Toggle explorer focus";

        # https://github.com/AstroNvim/AstroNvim/blob/v4.7.7/lua/astronvim/plugins/neo-tree.lua#L12-L18
        action.__raw = ''
          function()
            if vim.bo.filetype == "neo-tree" then
              vim.cmd.wincmd "p"
            else
              vim.cmd.Neotree "focus"
            end
          end
        '';
      }
    ];
  };
}
