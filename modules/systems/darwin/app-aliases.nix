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

        # Populate the directory with app aliases after copyApps finishes
        home.activation.aliasHomeManagerApplications = lib.hm.dag.entryAfter [ "copyApps" ] ''
          app_folder="/Users/${username}/Applications/${cfg.folder}"
          # Remove existing skeleton directories or broken aliases so mkalias succeeds
          if [ -d "$app_folder" ]; then
            rm -rf "$app_folder"/*
          else
            mkdir -p "$app_folder"
          fi
          # Create aliases for home-manager apps from the newly linked generation
          app_src=""
          if [ -d "$newGenPath/home-path/Applications" ]; then
            app_src="$newGenPath/home-path/Applications"
          elif [ -d "$genProfilePath/home-path/Applications" ]; then
            app_src="$genProfilePath/home-path/Applications"
          elif [ -d "$genProfilePath/Applications" ]; then
            app_src="$genProfilePath/Applications"
          fi

          if [ -n "$app_src" ]; then
            find "$app_src" -maxdepth 1 -name "*.app" | while read -r app; do
              real_app="$(readlink -f "$app" 2>/dev/null || realpath "$app" 2>/dev/null || true)"
              if [ -n "$real_app" ] && [ -d "$real_app" ]; then
                app_target="$app_folder/$(basename "$real_app")"
                $DRY_RUN_CMD ${pkgs.mkalias}/bin/mkalias "$real_app" "$app_target" || true
              fi
            done
          fi
        '';
      })
      enabledUsers;
  };
}
