{
  zsh     = import ./shell/zsh.nix;
  git     = import ./shell/git.nix;
  neovim  = import ./shell/neovim.nix;
  htop    = import ./shell/htop.nix;
  xbacklight = import ./shell/xbacklight.nix;

  awesomewm = import ./desktop/awesomewm.nix;
  ru-layout = import ./desktop/ru-layout.nix;
  touchpad  = import ./desktop/touchpad.nix;

  telegram    = import ./desktop/apps/telegram.nix;
  keepass     = import ./desktop/apps/keepass.nix;
  vlc         = import ./desktop/apps/vlc.nix;
  qbittorrent = import ./desktop/apps/qbittorrent.nix;

  vscode = import ./desktop/development/vscode.nix;

  alacritty = import ./desktop/terminal/alacritty.nix;
  kitty     = import ./desktop/terminal/kitty.nix;

  docker = import ./virtualization/docker.nix;
  development-common = import ./development/common.nix;

  options = import ./options.nix;
}