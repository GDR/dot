# Neovim editor backed by github:GDR/nvim.nix Flake
{ lib, inputs, ... }:

lib.my.mkFeature {
  description = "Neovim editor with Lua-first configuration";

  homeModule = { pkgs, ... }:
    let
      wrappedNeovim = inputs.nvim-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      home.packages = [ wrappedNeovim ] ++ (with pkgs; [ ripgrep fzf fd ]);
      xdg.configFile."nvim".source = "${inputs.nvim-nix}/dotfiles/nvim";
    };

  homeModuleLinux = { pkgs, ... }: {
    home.packages = [ pkgs.wl-clipboard ];
  };
}
