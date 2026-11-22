# Agentic — shared AI skills and rules repository sync, fanout, and harness wiring
{ lib, ... }:

lib.my.mkFeature {
  description = "Shared agentic skills and rules repository sync, fanout, and harness wiring";

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
        watchSubpaths = [
          "rules"
          "skills"
          "skills/design"
          "skills/git"
        ];
        fanout = [
          {
            from = "skills";
            into = [
              ".agents/skills"
              ".claude/skills"
            ];
            requireFile = "SKILL.md";
            recursive = true;
          }
        ];
        links = [
          {
            from = "rules/AGENTS.md";
            to = ".gemini/config/AGENTS.md";
          }
          {
            from = "rules/AGENTS.md";
            to = ".claude/CLAUDE.md";
          }
          {
            from = "rules/AGENTS.md";
            to = ".codex/AGENTS.md";
          }
          {
            from = "rules/AGENTS.md";
            to = ".config/opencode/AGENTS.md";
          }
          {
            from = "rules/AGENTS.md";
            to = ".gemini/GEMINI.md";
          }
        ];
      };

      home.file.".gemini/config/skills.json".text = builtins.toJSON {
        inherits = [
          { path = "${resolvedRepoPath}/skills.json"; }
        ];
      };
    };
}
