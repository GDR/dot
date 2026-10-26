{ lib
, stdenv
, fetchurl
, appimageTools
, unzip
, makeWrapper
,
}:

let
  pname = "learnharness";
  version = "0.3.7";

  meta = {
    description = "An agent harness for learning: adaptive teaching, practice, and a persistent knowledge graph";
    homepage = "https://github.com/amosblomqvist/learnharness";
    downloadPage = "https://github.com/amosblomqvist/learnharness/releases";
    license = lib.licenses.agpl3Only;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
    mainProgram = "learnharness";
  };

  linux =
    let
      src = fetchurl {
        url = "https://github.com/amosblomqvist/learnharness/releases/download/v${version}/LearnHarness-${version}-x86_64.AppImage";
        hash = "sha256-7zRlGDOxGOpcdEnM2UUFgBB66xg+bHGrFQdrQ7xFGOw=";
      };
      appimageContents = appimageTools.extract { inherit pname version src; };
    in
    appimageTools.wrapType2 {
      inherit
        pname
        version
        src
        meta
        ;

      extraInstallCommands = ''
        install -m 444 -D ${appimageContents}/learnharness.desktop -t $out/share/applications
        substituteInPlace $out/share/applications/learnharness.desktop \
          --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=learnharness %U'
        cp -r ${appimageContents}/usr/share/icons $out/share
      '';
    };

  darwin = stdenv.mkDerivation {
    inherit pname version meta;

    src = fetchurl {
      url = "https://github.com/amosblomqvist/learnharness/releases/download/v${version}/LearnHarness-${version}-arm64-mac.zip";
      hash = "sha256-WwfbG5j0ZMV9zfZ5h6jntWqwNPejIeXGdx1cFP8xcus=";
    };

    nativeBuildInputs = [
      unzip
      makeWrapper
    ];

    sourceRoot = ".";

    # Preserve macOS symlinks inside Electron Framework.framework
    unpackCmd = "unzip -q $curSrc";

    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/Applications" "$out/bin"
      cp -a "LearnHarness.app" "$out/Applications/"
      makeWrapper "$out/Applications/LearnHarness.app/Contents/MacOS/LearnHarness" "$out/bin/learnharness"

      runHook postInstall
    '';
  };
in
if stdenv.hostPlatform.isDarwin then darwin else linux
