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
        rev = "master";
        hash = "sha256-tnAFBxdXamEG2qAy4TVUB8dSQrGVUjlQPE42lK4aoiY=";
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
