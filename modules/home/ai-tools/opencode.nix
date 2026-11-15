{ lib, ... }:

lib.my.mkFeature {
  description = "OpenCode AI coding agent CLI";
  homeModule = _: {
    programs.opencode.enable = true;
  };
}
