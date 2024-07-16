{ inputs, config, options, lib, pkgs, ... }: with lib; {
  imports = [
    inputs.home-manager.darwinModules.home-manager
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];
  options = with types; { };
  config = {
    # Enable Home Manager applications in ~/Applications folder
    home.activation = {
      aliasHomeManagerApplications = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        app_folder="/Users/dgarifullin/Applications/Home Manager Trampolines"
        rm -rf "$app_folder"
        mkdir -p "$app_folder"
        echo "$genProfilePath"
        find "$genProfilePath/home-path/Applications" -type l -print | while read -r app; do
            app_target="$app_folder/$(basename "$app")"
            real_app="$(readlink "$app")"
            echo "mkalias \"$real_app\" \"$app_target\"" >&2
            $DRY_RUN_CMD ${pkgs.mkalias}/bin/mkalias "$real_app" "$app_target"
        done
      '';
    };

    # Enable homebrew
    homebrew = {
      enable = true;
    };

    nix-homebrew = {
      enable = true;
      user = "dgarifullin";
    };
  };
}
