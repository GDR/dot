{ config, pkgs, ... }: 
{
  home = {
    packages = with pkgs; [
      rofi
      wezterm
    ];

    file = {
      ".config/awesome" = { source = config.lib.file.mkOutOfStoreSymlink ./config; };
    };
  };
}