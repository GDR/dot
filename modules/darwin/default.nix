{ lib, ... }: {
  modules = lib.my.flattenModules (lib.my.recursiveDirs ./.);
}
