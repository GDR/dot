# omarchy-waybar — Omarchy scripts & indicators for Waybar (NixOS port)
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "linux" ];
  description = "Omarchy scripts & waybar indicators (NixOS port)";

  homeModuleLinux = { pkgs, ... }:
    let
      omarchy = pkgs.fetchFromGitHub {
        owner = "basecamp";
        repo = "omarchy";
        # Pin immutable commit SHA instead of floating "master" ref so fixed-output
        # hash stays reproducible across upstream pushes.
        rev = "f4378f0de5b44d331ee943746a97872b718a6c18";
        hash = "sha256-vPdvurq/4zRkpnnVLhvDCgVb7A8DNbLBKmd1nEqNr5A=";
      };

      omarchyBins = pkgs.runCommand "omarchy-bins"
        {
          nativeBuildInputs = [ pkgs.makeWrapper ];
        }
        ''
          mkdir -p $out/bin

          for f in ${omarchy}/bin/omarchy-*; do
            install -m 755 "$f" $out/bin/
          done
        '';
    in
    {
      home.packages = with pkgs; [
        omarchyBins
        btop
        networkmanagerapplet
        pavucontrol
        blueman
        wf-recorder
        slurp
        upower
        wttrbar
        pamixer
        pulseaudio
        xdg-terminal-exec
      ];

      home.sessionVariables = {
        OMARCHY_PATH = "${omarchy}";
      };
    };
}
