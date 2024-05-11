{ lib, ... }: with lib; with lib.my; let
  modulesCommon = flattenModules (recursiveDirs ./common);
  modulesDarwin = flattenModules (recursiveDirs ./darwin) ++ modulesCommon;
  modulesLinux = flattenModules (recursiveDirs ./linux) ++ modulesCommon;
in {
  inherit modulesCommon modulesDarwin modulesLinux;
}
