# App Aliases - Darwin-only system module
# Creates aliases in ~/Applications for home-manager apps so Spotlight can find them
{ config, lib, pkgs, ... }:
let
  cfg = config.systemDarwin.app-aliases;

  # Get enabled users to apply home.activation to each
  enabledUsers = lib.filterAttrs (_: u: u.enable) (config.hostUsers or { });
in
{
  options.systemDarwin.app-aliases = {
    enable = lib.mkEnableOption "Spotlight-compatible aliases for home-manager apps";

    folder = lib.mkOption {
      type = lib.types.str;
      default = "Home Manager Apps";
      description = "Folder name in ~/Applications for app aliases";
    };
  };

  config = lib.mkIf cfg.enable {
    # Apply home.activation to all enabled users
    home-manager.users = lib.mapAttrs
      (username: _: {
        home.activation.aliasHomeManagerApplications = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          app_folder="/Users/${username}/Applications/${cfg.folder}"
          rm -rf "$app_folder"
          mkdir -p "$app_folder"
          if [ -d "$genProfilePath/home-path/Applications" ]; then
            find "$genProfilePath/home-path/Applications" -type l -print | while read -r app; do
              app_target="$app_folder/$(basename "$app")"
              real_app="$(readlink "$app")"
              $DRY_RUN_CMD ${pkgs.mkalias}/bin/mkalias "$real_app" "$app_target"
            done
          fi
        '';
      })
      enabledUsers;
  };
}

