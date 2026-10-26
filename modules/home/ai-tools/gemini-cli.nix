# Gemini CLI - Google's AI coding assistant
{ lib, ... }:

lib.my.mkFeature {
  description = "Gemini CLI - Google's AI coding assistant";
  homeModule = { ... }: {
    programs.antigravity-cli = {
      enable = true;
    };
  };
}
