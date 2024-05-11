{ lib, stdenv, fetchurl }:
let
  pname = "apple-emoji-ttf";
  version = "v16.4";
in
stdenv.mkDerivation {
  inherit pname;
  inherit version;

  src = fetchurl {
    url = "https://github.com/samuelngs/apple-emoji-linux/releases/download/${version}/AppleColorEmoji.ttf";
    sha256 = "sha256-goY9lWBtOnOUotitjVfe96zdmjYTPT6PVOnZ0MEWh0U=";
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