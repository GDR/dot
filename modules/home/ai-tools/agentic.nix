# Agentic — shared AI skills repository sync, fanout, and Antigravity wiring
{ lib, ... }:

lib.my.mkFeature {
  description = "Shared agentic skills repository sync, fanout, and Antigravity wiring";

  homeModule =
    { config, lib, ... }:
    let
      repoPath = config.programs.detachedRepos.repos.agentic.path;
      resolvedRepoPath =
        if repoPath == "~" then
          config.home.homeDirectory
        else if lib.hasPrefix "/" repoPath then
          repoPath
        else if lib.hasPrefix "~/" repoPath then
          "${config.home.homeDirectory}/${lib.removePrefix "~/" repoPath}"
        else
          "${config.home.homeDirectory}/${lib.removePrefix "./" repoPath}";
    in
    {
      programs.detachedRepos.repos.agentic = {
        pullUrl = "https://github.com/GDR/agentic.git";
        pushUrl = "git@github.com:GDR/agentic.git";
        path = "Workspaces/gdr/agentic";
        branch = "main";
        autoPull = true;
        interval = 300;
        watch = true;
        watchSubpaths = [ "skills" ];
        fanout = [
          {
            from = "skills";
            into = [
              ".agents/skills"
              ".claude/skills"
            ];
            requireFile = "SKILL.md";
          }
        ];
        links = [ ];
      };

      home.file.".gemini/config/skills.json".text = builtins.toJSON {
        entries = [
          { path = "${resolvedRepoPath}/skills"; }
        ];
      };
    };
}
