# Tag-based module enablement
# Each module checks these options to determine if it should be enabled
{ config, lib, ... }: with lib;
{
  options.modules.tags = {
    enable = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Enable all modules with these tags (e.g., [\"media\" \"ui\"])";
      example = [ "media" "desktop" ];
    };
    
    explicit = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Explicitly enable these modules by path";
      example = [ "common.media.vlc" ];
    };
  };
  
  # No config block - modules check tags themselves to avoid circular dependency
}
