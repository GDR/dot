{ self, inputs, pkgs, lib, system }:

let
  user = "dgarifullin";
  hasPackage = prefix: packages:
    lib.any (package: lib.hasPrefix prefix (package.name or "")) packages;

  neovimConfig = inputs.nvim-nix.checks.${system}.neovim-config;
in
if system == "x86_64-linux" then
  let
    home = self.nixosConfigurations.nix-goldstar.config.home-manager.users.${user}.home;
  in
  {
    module-platform-merge =
      assert hasPackage "ripgrep-" home.packages;
      assert hasPackage "wl-clipboard-" home.packages;
      assert hasPackage "google-antigravity-ide-with-basic-store" home.packages;
      assert home.file ? ".gemini/config/AGENTS.md";
      pkgs.runCommand "module-platform-merge-check" { } "touch $out";

    neovim-config = neovimConfig;
  }
else if system == "aarch64-darwin" then
  let
    home = self.darwinConfigurations.mac-brightstar.config.home-manager.users.${user}.home;
  in
  {
    module-platform-merge =
      assert hasPackage "ripgrep-" home.packages;
      assert !(hasPackage "wl-clipboard-" home.packages);
      pkgs.runCommand "module-platform-merge-check" { } "touch $out";

    neovim-config = neovimConfig;
  }
else
  { }
