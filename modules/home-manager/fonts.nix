{ pkgs, lib, config, ... }:
let 
    cfg = config.fontProfiles;
in {
  config = {
    fonts.fontconfig.enable = true;
    home.packages = with pkgs; [ 
      (nerdfonts.override { fonts = [ "Hack" ]; })
    ];
  };
}