{ lib, ... }: with lib; with lib.my; {
  modules = flattenModules (recursiveDirs ./.);
}
