# macOS system profile — standard Darwin system setup
{ lib, system, ... }:
lib.optionalAttrs (lib.hasSuffix "-darwin" system) {
  modules.system.darwin = {
    macos-settings.enable = lib.mkDefault true;
  };
}
