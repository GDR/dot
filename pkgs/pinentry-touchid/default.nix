{ lib, stdenv, buildGoModule, fetchFromGitHub, apple-sdk_15 }:

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

  buildInputs = [
    apple-sdk_15
  ];

  meta = with lib; {
    description = "Pinentry program for GnuPG that uses macOS Touch ID";
    homepage = "https://github.com/lujstn/pinentry-touchid";
    license = licenses.asl20;
    platforms = platforms.darwin;
  };
}
