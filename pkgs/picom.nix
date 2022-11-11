{ picom, lib, fetchFromGitHub }:

picom.overrideAttrs (oldAttrs: rec {
  pname = "picom-jonaburg";
  version = "unstable-2022-02-05";
  src = fetchFromGitHub {
    owner = "jonaburg";
    repo = "picom";
    rev = "e3c19cd7d1108d114552267f302548c113278d45";
    sha256 = "sha256-4voCAYd0fzJHQjJo4x3RoWz5l3JJbRvgIXn1Kg6nz6Y=";
  };
  meta.maintainers = with lib.maintainers; oldAttrs.meta.maintainers ++ [ GosuGDR ];
})