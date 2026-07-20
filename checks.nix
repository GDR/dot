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
    run_neovim_check() {
      local root="$1"

      export HOME="$root/home"
      export XDG_CONFIG_HOME="$root/config"
      export XDG_DATA_HOME="$root/data"
      export XDG_STATE_HOME="$root/state"
      export XDG_CACHE_HOME="$root/cache"
      export NVIM_LOG_FILE="$root/nvim.log"

      mkdir -p \
        "$HOME" \
        "$XDG_CONFIG_HOME" \
        "$XDG_DATA_HOME" \
        "$XDG_STATE_HOME" \
        "$XDG_CACHE_HOME"

      if [ ! -d "$XDG_CONFIG_HOME/nvim" ]; then
        cp -R ${./modules/home/editors/neovim/dotfiles/nvim} "$XDG_CONFIG_HOME/nvim"
        chmod -R u+w "$XDG_CONFIG_HOME/nvim"
      fi

      nvim --headless -c "luafile ${./modules/home/editors/neovim/tests/check.lua}"
    }

    run_neovim_check "$TMPDIR/valid"

    broken_root="$TMPDIR/broken"
    mkdir -p "$broken_root/config"
    cp -R ${./modules/home/editors/neovim/dotfiles/nvim} "$broken_root/config/nvim"
    chmod -R u+w "$broken_root/config/nvim"
    printf 'error("intentional plugin configuration failure")\n' \
      > "$broken_root/config/nvim/lua/plugins/zz-check-failure.lua"

    if run_neovim_check "$broken_root"; then
      echo "Neovim check accepted a broken plugin configuration" >&2
      exit 1
    fi

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
