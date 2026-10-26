# VS Code Server — remote development daemon for VS Code / Cursor / Antigravity IDE
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "linux" ];
  description = "VS Code Server / Antigravity IDE remote development daemon";

  nixosModule = { pkgs, ... }: {
    services.vscode-server = {
      enable = true;

      installPath = [
        "$HOME/.vscode-server"
        "$HOME/.antigravity-ide-server"
        "$HOME/.antigravity-server"
      ];

      extraRuntimeDependencies = [ pkgs.procps ];
    };

    programs.nix-ld.enable = true;

    environment.systemPackages = [ pkgs.procps ];
  };
}
