{ lib, stdenv, buildGoModule, fetchFromGitHub, apple-sdk_15, pinentry_mac, makeWrapper }:

buildGoModule rec {
  pname = "pinentry-touchid";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "lujstn";
    repo = "pinentry-touchid";
    rev = "main";
    hash = "sha256-cEKR1vhXkb/liwjwCVJ/AH/MKgNH5z8fyLSXbxgxBjk=";
  };

  subPackages = [ "." ];
  proxyVendor = true;
  vendorHash = "sha256-v3JtUk94/javwhtUsPUFV9EwFfaixZpb4AqKpCEaZp4=";
  doCheck = false;

  postPatch = ''
    substituteInPlace main.go \
      --replace-fail 'query := keychain.NewItem()' 'query := keychain.NewItem(); query.SetService("GnuPG")'
  '';

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [
    apple-sdk_15
    pinentry_mac
  ];

  postInstall = ''
    wrapProgram $out/bin/pinentry-touchid \
      --prefix PATH : ${lib.makeBinPath [ pinentry_mac ]}
  '';

  meta = with lib; {
    description = "Pinentry program for GnuPG that uses macOS Touch ID";
    homepage = "https://github.com/lujstn/pinentry-touchid";
    license = licenses.asl20;
    platforms = platforms.darwin;
  };
}
