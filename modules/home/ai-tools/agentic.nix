# Agentic — shared AI skills and rules repository sync, fanout, and harness wiring
{ lib, inputs, ... }:

let
  layout = inputs.agentic.lib.layout;
in
lib.my.mkFeature {
  description = "Shared agentic skills and rules repository sync, fanout, and harness wiring";

  homeModule =
    { config, ... }:
    {
      programs.detachedRepos.repos.agentic = {
        pullUrl = "https://github.com/GDR/agentic.git";
        pushUrl = "git@github.com:GDR/agentic.git";
        path = "Workspaces/gdr/agentic";
        branch = "main";
        autoPull = true;
        interval = 300;
        watch = true;
        inherit (layout)
          watchSubpaths
          fanout
          links
          ;
      };

      programs.agentic = {
        enable = true;
        repoPath = config.programs.detachedRepos.repos.agentic.path;
      };
    };
}
