{ lib, ... }: with lib; with types; rec {
  mkBoolOpt = default:
    mkOption {
      inherit default;
      type = bool;
      example = true;
    };

  recursiveDirs = dir: mapAttrs' (n: v:
    if v == "directory" then nameValuePair n (recursiveDirs "${toString dir}/${n}")
    else nameValuePair (removeSuffix ".nix" n) "${toString dir}/${n}"
  ) (builtins.readDir dir);

  flattenModules = modules: (
    concatMap (x:
      if isAttrs modules.${x} then (flattenModules modules.${x})
      else if x == "default" || x == "_default" then []
      else [modules.${x}]
    ) (attrNames modules)
  );

  mkModule = config: name: cfg: let
    optionsVal = mkOption {
      default = false;
      type = types.bool;
    };
    options = {
      modules = setAttrByPath name optionsVal;
    };
    defaultEnabled = { enable = false; };
    enabled = (attrByPath name defaultEnabled config).enable;
  in {
    inherit options;
    config = mkIf enabled cfg.config;
  };
}