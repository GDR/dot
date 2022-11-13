{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      nil
      gnumake
      pipenv
      jetbrains.idea-community
    ];
  };
}