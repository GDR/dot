{ lib, ... }: with lib; with lib.my; rec {
  modules = flattenModules (recursiveDirs ./.);
}
