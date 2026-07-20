# ghidra-aeon — AEON R2 processor plugin for Ghidra.
# Pure Sleigh extension (no Java/gradle): invokes Ghidra's sleigh binary
# directly to compile .slaspec → .sla, then installs into the path layout
# that buildGhidraExtension and ghidra.withExtensions expect:
#   $out/lib/ghidra/Ghidra/Extensions/<pname>/
{ lib
, fetchFromGitHub
, buildGhidraExtension
, ghidra
,
}:
buildGhidraExtension (finalAttrs: {
  pname = "ghidra-aeon";
  version = "0-unstable-2023-02-25";

  src = fetchFromGitHub {
    owner = "shinyquagsire23";
    repo = "ghidra-aeon";
    rev = "de8a2539d474efa409ba458c565bc74f9e5e0b1d";
    hash = "sha256-xpSZ/HLXIOYnFcNIpCgwTGFJVfmaWg0BW5Fx9hie0b8=";
  };

  # Fix two upstream bugs in aeon.slaspec: bit fields named uimm<start>_<width>
  # but declared with inverted range (high, low) which Sleigh rejects.
  # i16_uimm4_2 and i24_uimm4_2 = (4,2) must be (4,5): 2 bits from bit 4.
  # (i32_uimm4_2 = (4,5) on line 131 is already correct.)
  postPatch = ''
    sed -i 's/i16_uimm4_2 = (4, 2)/i16_uimm4_2 = (4, 5)/' data/languages/aeon.slaspec
    sed -i 's/i24_uimm4_2 = (4, 2)/i24_uimm4_2 = (4, 5)/' data/languages/aeon.slaspec
  '';

  # buildGhidraExtension adds jdk to nativeBuildInputs — needed by sleigh.
  # Skip gradle (no build.gradle); compile Sleigh and install manually.
  buildPhase = ''
    runHook preBuild

    # Compile .slaspec → .sla using Ghidra's built-in sleigh launcher
    ${ghidra}/lib/ghidra/support/sleigh -i data/sleighArgs.txt -a data/languages

    runHook postBuild
  '';

  # Must mirror the layout buildGhidraExtension's default installPhase produces:
  #   $out/lib/ghidra/Ghidra/Extensions/<pname>/
  # withExtensions (symlinkJoin) needs this path to merge correctly with ghidra.
  installPhase = ''
        runHook preInstall

        ext="$out/lib/ghidra/Ghidra/Extensions/${finalAttrs.pname}"
        mkdir -p "$ext"

        cp Module.manifest "$ext/"
        cp -r data "$ext/"

        # extension.properties required by Ghidra's extension loader
        cat > "$ext/extension.properties" <<EOF
    name=${finalAttrs.pname}
    description=AEON R2 processor for Ghidra
    version=12.1.2
    EOF

        # Lock file prevents Ghidra from trying to write into the Nix store
        touch "$ext/.dbDirLock"

        runHook postInstall
  '';

  meta = {
    description = "AEON R2 processor plugin for Ghidra";
    homepage = "https://github.com/shinyquagsire23/ghidra-aeon";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
})
