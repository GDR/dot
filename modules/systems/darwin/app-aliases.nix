# App Aliases - Darwin-only system module
# Creates aliases in ~/Applications for home-manager apps so Spotlight can find them
{ lib, pkgs, config, ... }@args:

let
  enabledUsers = lib.filterAttrs (_: u: u.enable) (config.hostUsers or { });
in
lib.my.mkSystemModuleV2 args {
  namespace = "darwin";
  description = "Spotlight-compatible aliases for home-manager apps";

  extraOptions = {
    folder = lib.mkOption {
      type = lib.types.str;
      default = "Home Manager Apps";
      description = "Folder name in ~/Applications for app aliases";
    };
  };

  module = cfg: {
    home-manager.users = lib.mapAttrs
      (username: _: {
        # Override nix-darwin's linkapps module with our custom implementation
        # Use mkForce to override the default Applications/Home Manager Apps link
        home.file."Applications/${cfg.folder}" = {
          source = lib.mkForce (pkgs.runCommand "app-aliases-dir" { } "mkdir -p $out");
          recursive = true;
          force = true;
        };

        # Populate the directory with app aliases after files are written
        home.activation.aliasHomeManagerApplications = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          app_folder="/Users/${username}/Applications/${cfg.folder}"
          # Remove existing aliases to avoid duplicates
          if [ -d "$app_folder" ]; then
            find "$app_folder" -type f -delete
          fi
          # Create aliases for home-manager apps
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
