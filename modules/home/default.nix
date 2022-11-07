{ pkgs, config, ... }:
{
  home.stateVersion = "22.05";

  home.packages = with pkgs; [
    zsh
    alacritty
    firefox
    vscode
    neovim
    wget
  ];
}