# Google Cloud SDK (gcloud CLI)
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "darwin" ];
  description = "Google Cloud SDK (gcloud, gsutil, bq)";
  homeModuleDarwin = { pkgs, ... }: {
    home.packages = [ pkgs.google-cloud-sdk ];
  };
}
