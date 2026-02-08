# Power management - Linux system module (TLP, upower, lid switch)
{ lib, ... }@args:

lib.my.mkSystemModuleV2 args {
  namespace = "linux";
  description = "Power management with TLP, upower, and lid switch control";

  extraOptions = {
    tlp = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable TLP power management (for laptops)";
    };

    upower = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable upower battery power management";
    };

    lidSwitch = lib.mkOption {
      type = lib.types.enum [ "suspend" "hibernate" "hybrid-sleep" "lock" "ignore" ];
      default = "suspend";
      description = "Action to take when laptop lid is closed";
    };
  };

  module = cfg: {
    # TLP power management
    services.tlp.enable = cfg.tlp;

    # Battery power management
    services.upower.enable = cfg.upower;

    # Lid switch behavior
    services.logind.settings.Login.HandleLidSwitch = cfg.lidSwitch;
  };
}
