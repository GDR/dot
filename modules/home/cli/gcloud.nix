# Google Cloud SDK (gcloud CLI)
# Darwin-only — Linux infra hosts get gcloud via the vantage devshell.
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "darwin" ];
  description = "Google Cloud SDK (gcloud, gsutil, bq)";
  module = {
    darwinSystems.home.packages = [ pkgs.google-cloud-sdk ];
  };
}
