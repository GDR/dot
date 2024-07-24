{ ... }:
let
  icons = (import ../utils/icons.nix).icons;
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
