# LearnHarness - An agent harness for learning
{ lib, pkgs ? null, ... }:

let
  modelSlotOption = description:
    lib.mkOption {
      type = lib.types.nullOr (lib.types.submodule {
        options = {
          provider = lib.mkOption {
            type = lib.types.str;
            description = "Provider ID (e.g. 'antigravity', 'anthropic', 'openai', 'openrouter').";
          };
          id = lib.mkOption {
            type = lib.types.str;
            description = "Model ID within the provider.";
          };
          thinkingLevel = lib.mkOption {
            type = lib.types.nullOr (lib.types.enum [ "off" "minimal" "low" "medium" "high" "xhigh" "max" ]);
            default = null;
            description = "Optional thinking budget level.";
          };
        };
      });
      default = null;
      inherit description;
    };
in
lib.my.mkFeature {
  platforms = [
    "linux"
    "darwin"
  ];
  description = "LearnHarness - An agent harness for learning";

  extraOptions = {
    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = if pkgs != null && pkgs ? learnharness then pkgs.learnharness else null;
      description = "LearnHarness package to install.";
    };

    autoUpdate = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether LearnHarness should check for automatic updates.";
    };

    obsidianFolders = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "~/obsidian-vault" ];
      description = "Obsidian vault/project folder paths where agent Markdown write/edit tools are allowed to operate.";
    };

    models = {
      strong = modelSlotOption "Strong model slot (used by prober and teacher agents).";
      cheap = modelSlotOption "Cheap/fast model slot (used by researcher, demoBuilder, extractor, auditor).";
      vision = modelSlotOption "Vision model slot (used by visualMaker and pdfReader).";
    };

    tools = lib.mkOption {
      type = lib.types.attrsOf lib.types.bool;
      default = { };
      description = "Per-tool enable/disable overrides (absent = enabled).";
    };

    searchEngine = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "brave" "exa" "perplexity" "serper" "tavily" ]);
      default = null;
      description = "Preferred web search engine when multiple search API keys are configured.";
    };

    graphTools = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = "Whether prober knowledge-graph inspection tools are enabled.";
    };

    extraSettings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Additional raw settings deep-merged into settings.json.";
    };
  };

  homeModule = { pkgs, featureCfg, ... }: {
    programs.learnharness = {
      enable = true;
      package = if (featureCfg.package or null) != null then featureCfg.package else pkgs.learnharness;
      inherit (featureCfg)
        autoUpdate
        obsidianFolders
        models
        tools
        searchEngine
        graphTools
        extraSettings
        ;
    };
  };
}
