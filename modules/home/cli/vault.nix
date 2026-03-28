# HashiCorp Vault CLI
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  description = "HashiCorp Vault CLI";
  module = {
    allSystems.home.packages = [ pkgs.vault ];
  };
}
