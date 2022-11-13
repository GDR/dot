# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{ inputs, lib, config, pkgs, environment, ... }: 
{
  imports = [
    # If you want to use home-manager modules from other flakes (such as nix-colors), use something like:
    # inputs.nix-colors.homeManagerModule

    # Feel free to split up your configuration and import pieces of it here.
    ./desktop
    ./terminal
  ];

  home.sessionVariables.EDITOR = "nvim";
  nixpkgs.config.allowUnfree = true;

  home = {
    username = "gdr";
    homeDirectory = "/home/gdr";

    packages = with pkgs; [
      tdesktop # Telegram
      qbittorrent
      keepassxc
      mpv
      vlc
      google-chrome
    ];

    file = {
      ".config/alacritty" = { source = config.lib.file.mkOutOfStoreSymlink ../dotfiles/alacritty; };
    };
  };
  
  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  # home.packages = with pkgs; [ steam ];

  # Enable home-manager and git
  programs.home-manager.enable = true;
  programs.alacritty.enable = true;
  programs.vscode.enable = true;

  programs = {
    git = {
      enable = true;
      userName = "Damir Garifullin";
      userEmail = "gosugdr@gmail.com";
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      shellAliases = {
        "ls" = "ls -l --color --group-directories-first";
        "dotfiles" = "cd ~/.config/nixos";
      };
      plugins = [
        {
          name = "zsh-nix-shell";
          file = "nix-shell.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "chisui";
            repo = "zsh-nix-shell";
            rev = "v0.5.0";
            sha256 = "0za4aiwwrlawnia4f29msk822rj9bgcygw6a8a6iikiwzjjz0g91";
          };
        }
      ];
      oh-my-zsh = {
        enable = true;
        plugins = [ 
          "git"
        ];
        theme = "agnoster";
      };
    };

    neovim = {
      enable = true;
    };
  };
  

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.05";
}
