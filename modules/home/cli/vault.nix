# HashiCorp Vault CLI
{ lib, ... }:

lib.my.mkFeature {
  description = "HashiCorp Vault CLI";
  homeModule = { pkgs, ... }: {
    home.packages = [ pkgs.vault ];
  };
}
