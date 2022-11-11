{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      nil
      gnumake
    ];
  };
}