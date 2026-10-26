# Codex - OpenAI's AI coding agent
{ lib, ... }:

lib.my.mkFeature {
  description = "Codex - OpenAI's AI coding agent CLI";
  homeModule = _: {
    programs.codex = {
      enable = true;
    };
  };
}
