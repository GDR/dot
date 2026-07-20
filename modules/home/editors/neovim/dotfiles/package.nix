{ inputs, pkgs, lib }:

let
  pluginConfig = import ./plugins.nix { inherit pkgs lib; };
in
inputs.nix-wrapper-modules.wrappers.neovim.wrap {
  pkgs = pkgs // { _type = "pkgs"; };
  inherit (pluginConfig) specs runtimePkgs;
}
