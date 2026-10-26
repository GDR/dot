{ self, inputs, pkgs, lib, system }:

let
  user = "dgarifullin";
  hasPackage = nameOrPrefix: packages:
    lib.any (package:
      let
        pname = package.pname or "";
        name = package.name or "";
      in
      pname == nameOrPrefix ||
      lib.hasPrefix "${nameOrPrefix}-" name ||
      lib.hasPrefix nameOrPrefix name ||
      name == nameOrPrefix
    ) packages;

  neovimConfig = inputs.nvim-nix.checks.${system}.neovim-config;

  commonChecks = {
    mcp-config-generation =
      let
        goldstarHome = self.nixosConfigurations.nix-goldstar.config.home-manager.users.${user}.home;
        mcpFile = goldstarHome.file.".gemini/antigravity/mcp_config.json" or null;
        mcpJson = if mcpFile != null then builtins.fromJSON mcpFile.text else { };
      in
      assert goldstarHome.file ? ".gemini/antigravity/mcp_config.json";
      assert mcpJson ? mcpServers.nixos;
      assert mcpJson ? mcpServers.ghidra;
      pkgs.runCommand "mcp-config-generation-check" { } "touch $out";

    multi-user-isolation =
      let
        testHost = self.nixosConfigurations.nix-goldstar.extendModules {
          modules = [
            {
              hostUsers.bob = {
                enable = true;
                modules = {
                  home.cli.htop.enable = true;
                  home.games.soundpad.enable = true;
                };
              };
            }
          ];
        };
        bobPkgs = testHost.config.home-manager.users.bob.home.packages;
        bobFiles = testHost.config.home-manager.users.bob.home.file;
        bobGroups = testHost.config.users.users.bob.extraGroups or [ ];
        dgarifullinPkgs = testHost.config.home-manager.users.${user}.home.packages;
        dgarifullinFiles = testHost.config.home-manager.users.${user}.home.file;
        dgarifullinGroups = testHost.config.users.users.${user}.extraGroups or [ ];
      in
      # bob receives htop
      assert hasPackage "htop" bobPkgs;
      # bob receives pamixer/pavucontrol (via transitive requires audio)
      assert hasPackage "pamixer" bobPkgs;
      assert hasPackage "pavucontrol" bobPkgs;
      # bob does NOT receive telegram-desktop, google-antigravity-ide, .gemini/antigravity/mcp_config.json, or docker group
      assert !(hasPackage "telegram-desktop" bobPkgs);
      assert !(hasPackage "google-antigravity" bobPkgs);
      assert !(bobFiles ? ".gemini/antigravity/mcp_config.json");
      assert !(lib.elem "docker" bobGroups);
      # dgarifullin retains all of their packages, configs, and groups
      assert hasPackage "htop" dgarifullinPkgs;
      assert hasPackage "telegram-desktop" dgarifullinPkgs;
      assert (dgarifullinFiles ? ".gemini/antigravity/mcp_config.json");
      assert (lib.elem "docker" dgarifullinGroups);
      pkgs.runCommand "multi-user-isolation-check" { } "touch $out";

    cascade-child-opt-out =
      let
        testDarwin = self.darwinConfigurations.mac-brightstar.extendModules {
          modules = [
            {
              hostUsers.${user}.modules = {
                home.utils.enable = lib.mkForce true;
                home.utils.raycast.enable = lib.mkForce false;
              };
            }
          ];
        };
        pkgsList = testDarwin.config.home-manager.users.${user}.home.packages;
      in
      # obsidian is enabled via category cascade
      assert hasPackage "obsidian" pkgsList;
      # raycast remains disabled via child opt-out
      assert !(hasPackage "raycast" pkgsList);
      pkgs.runCommand "cascade-child-opt-out-check" { } "touch $out";

    neovim-config = neovimConfig;
  };
in
if system == "x86_64-linux" then
  let
    home = self.nixosConfigurations.nix-goldstar.config.home-manager.users.${user}.home;
  in
  commonChecks // {
    module-platform-merge =
      assert hasPackage "ripgrep-" home.packages;
      assert hasPackage "wl-clipboard-" home.packages;
      assert hasPackage "google-antigravity-ide-with-basic-store" home.packages;
      assert home.file ? ".gemini/config/AGENTS.md";
      pkgs.runCommand "module-platform-merge-check" { } "touch $out";
  }
else if system == "aarch64-darwin" then
  let
    home = self.darwinConfigurations.mac-brightstar.config.home-manager.users.${user}.home;
  in
  commonChecks // {
    module-platform-merge =
      assert hasPackage "ripgrep-" home.packages;
      assert !(hasPackage "wl-clipboard-" home.packages);
      pkgs.runCommand "module-platform-merge-check" { } "touch $out";
  }
else
  { }
