{ config, pkgs, ... }: 
{
  home = {
    packages = with pkgs; [
      rofi
    ];
  };
  home.file = {
    ".config/awesome".source = config.lib.file.mkOutOfStoreSymlink ./config;
  };
}