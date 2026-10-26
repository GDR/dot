# Codex - OpenAI's AI coding agent
{ lib, ... }:

lib.my.mkFeature {
  description = "Codex - OpenAI's AI coding agent CLI";
  homeModule = { ... }: {
    programs.codex = {
      enable = true;
    };
  };
}
