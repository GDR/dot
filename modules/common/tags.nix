{ config, lib, ... }: with lib;
let
  cfg = config.modules.tags;
  
  # Get module registry from common module
  # This is set by modules/common/default.nix
  # Filter out tags.nix itself to avoid circular dependency
  registry = config._moduleRegistry or { modules = []; };
  registryModules = filter (m: m.path != "common.tags") registry.modules;
  
  # Resolve enabled modules based on tags and explicit enables
  enabledModules = lib.my.resolveEnabledModules 
    registryModules 
    cfg.enable 
    cfg.explicit;
in
{
  options.modules.tags = {
    enable = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Enable all modules with these tags (e.g., [\"ui\" \"server\"])";
      example = [ "browser" "desktop" ];
    };
    
    explicit = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Explicitly enable these modules by path";
      example = [ "common.shell.git" ];
    };
  };
  
  config = lib.mkMerge (
    # Enable modules based on tags and dependencies
    map (modulePath:
      let
        # Convert "common.browsers.firefox" to config path parts
        pathParts = lib.my.pathToConfigParts modulePath;
        # Skip "common" prefix
        configParts = tail pathParts;  # Remove "common", keep ["browsers", "firefox"]
      in
      {
        # Build nested attribute set to enable the module
        # e.g., modules.common.browsers.firefox.enable = true
        modules.common = lib.setAttrByPath configParts { enable = true; };
      }
    ) enabledModules
  );
}
