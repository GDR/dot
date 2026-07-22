# Secretive - Secure Enclave SSH key agent for macOS
{ lib, ... }@args:

lib.my.mkModuleV2 args {
  description = "Secretive Secure Enclave SSH key agent";
  platforms = [ "darwin" ];

  module = {
    darwinSystems = {
      homebrew.casks = [ "secretive" ];
    };
  };
}
