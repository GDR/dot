# Caveman skills for Antigravity IDE
# Fetches the skills/ directory from the caveman repository.
# Provides ultra-compressed communication mode that cuts output tokens by ~65%.
# Source: https://github.com/JuliusBrussee/caveman
{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
  pname = "caveman-skills";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "JuliusBrussee";
    repo = "caveman";
    rev = "main";
    hash = "sha256-VqRHx3/4SSCnEh3cUJ/he5saIfwNhS0hOzoH/wwtU2o=";
  };

  # Only install the skills/ directory — that's all Antigravity needs
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r skills/* $out/
    runHook postInstall
  '';

  meta = {
    description = "Caveman skills for AI coding agents — ultra-compressed communication mode";
    homepage = "https://github.com/JuliusBrussee/caveman";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
