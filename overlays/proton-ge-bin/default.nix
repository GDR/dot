# Pin proton-ge-bin to a specific GE-Proton release
final: prev: {
  proton-ge-bin = prev.proton-ge-bin.overrideAttrs (_oldAttrs:
    let
      version = "GE-Proton10-32";
    in
    {
      inherit version;
      src = final.fetchzip {
        url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/${version}.tar.gz";
        hash = "sha256-NxZ4OJUYQdRNQTb62jRET6Ef14LEhynOASIMPvwWeNA=";
      };
    });
}
