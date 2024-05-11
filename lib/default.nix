{ lib, ... }: with lib; with types; rec {
  mkBoolOpt = default:
    mkOption {
      inherit default;
      type = bool;
      example = true;
    };

  recursiveDirs = dir:
    let files = filterAttrs (n: v: hasSuffix ".nix" n || v == "directory") (builtins.readDir dir); in (mapAttrs'
      (n: v:
        if v == "directory" then nameValuePair n (recursiveDirs "${toString dir}/${n}")
        else
          let name = removeSuffix ".nix" n;
          in nameValuePair name "${toString dir}/${n}"
      )
    ) files;

  flattenModules = modules: (
    concatMap
      (x:
        if x == [ ] || x == "default" || x == "_default" then [ ]
        else if isAttrs modules.${x} then (flattenModules modules.${x})
        else [ modules.${x} ]
      )
      (attrNames modules)
  );

  filterPrefix = prefix: files:
    builtins.filter (file: builtins.hasPrefix prefix (builtins.basename file)) files;

  mkModule = config: name: cfg:
    let
      optionsVal = {
        enable = mkOption {
          default = false;
          type = types.bool;
        };
      };
      options = {
        modules = setAttrByPath name optionsVal;
      };
      defaultEnabled = { enable = false; };
      enabled = (attrByPath name defaultEnabled config.modules).enable;
    in
    {
      inherit options;
      config = mkIf enabled cfg.config;
    };
}
