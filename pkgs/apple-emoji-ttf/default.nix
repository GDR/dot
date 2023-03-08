
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
    description = "Color emoji SVGinOT font using Twitter Unicode 10 emoji with diversity and country flags";
    longDescription = ''
      A color and B&W emoji SVGinOT font built from the Twitter Emoji for
      Everyone artwork with support for ZWJ, skin tone diversity and country
      flags.
      The font works in all operating systems, but will currently only show
      color emoji in Firefox, Thunderbird, Photoshop CC 2017, and Windows Edge
      V38.14393+. This is not a limitation of the font, but of the operating
      systems and applications. Regular B&W outline emoji are included for
      backwards/fallback compatibility.
    '';
    homepage = "https://github.com/eosrei/twemoji-color-font";
    downloadPage = "https://github.com/eosrei/twemoji-color-font/releases";
    license = with licenses; [ cc-by-40 mit ];
    maintainers = [ maintainers.fgaz ];
  };
}