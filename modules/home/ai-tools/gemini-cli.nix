# Gemini CLI - Google's AI coding assistant
{ lib, ... }:

lib.my.mkFeature {
  description = "Gemini CLI - Google's AI coding assistant";
  homeModule = _: {
    programs.antigravity-cli = {
      enable = true;
    };
  };
}
