
{ lib, stdenv, fetchurl }:
let
  pname = "apple-emoji-ttf";
  version = "15.4";
in
stdenv.mkDerivation {
  inherit pname;
  inherit version;

  src = fetchurl {
    url = "https://github.com/samuelngs/apple-emoji-linux/releases/download/ios-${version}/AppleColorEmoji.ttf";
    sha256 = "sha256-CDmtLCzlytCZyMBDoMrdvs3ScHkMipuiXoNfc6bfimw=";
  };

  dontUnpack = true;
  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    install -Dm755 $src $out/share/fonts/truetype/AppleColorEmoji.ttf
  '';

  meta = with lib; {
    description = "Color emoji font using Apple Color Emojis with diversity and country flags";
    homepage = "https://github.com/samuelngs/apple-emoji-linux/";
    downloadPage = "https://github.com/samuelngs/apple-emoji-linux/releases";
    license = with licenses; [ asl20 ];
    maintainers = [ maintainers.gdr ];
  };
}