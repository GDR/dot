{ self, inputs, pkgs, lib, system }:

let
  user = "dgarifullin";
  hasPackage = prefix: packages:
    lib.any (package: lib.hasPrefix prefix (package.name or "")) packages;

  neovim = import ./modules/home/editors/neovim/dotfiles/package.nix {
    inherit inputs pkgs lib;
  };

  neovimConfig = pkgs.runCommand "neovim-config-check"
    {
      nativeBuildInputs = [ neovim ];
    } ''
    export HOME="$TMPDIR/home"
    export XDG_CONFIG_HOME="$TMPDIR/config"
    export XDG_DATA_HOME="$TMPDIR/data"
    export XDG_STATE_HOME="$TMPDIR/state"
    export XDG_CACHE_HOME="$TMPDIR/cache"
    export NVIM_LOG_FILE="$TMPDIR/nvim.log"

    mkdir -p \
      "$HOME" \
      "$XDG_CONFIG_HOME" \
      "$XDG_DATA_HOME" \
      "$XDG_STATE_HOME" \
      "$XDG_CACHE_HOME"
    ln -s ${./modules/home/editors/neovim/dotfiles/nvim} "$XDG_CONFIG_HOME/nvim"

    nvim --headless -l ${./modules/home/editors/neovim/tests/check.lua}
    touch "$out"
  '';
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
