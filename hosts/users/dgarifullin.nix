# Default values for dgarifullin user
# Import in hosts and reference by section:
#   hostUsers.dgarifullin = defaults.user // { enable = true; keys = [...]; ssh = [...] ++ defaults.ssh.knownHosts; };
#   modules.home.editors.antigravity = defaults.antigravity;
{ lib, ... }:

{
  # hostUsers-compatible fields — passed via `defaults.user // { ... }`
  user = {
    fullName = "Damir Garifullin";
    email = "gosugdr@gmail.com";
    github = "gdr";
    extraGroups = [ "wheel" "audio" "libvirtd" "input" ];
    uid = 1000;
  };

  # SSH topology — host-invariant entries appended to each machine's ssh list.
  # Keys and identity files are still specified per-host.
  ssh.knownHosts = [
    { host = "nix-oldstar"; forwardAgent = true; }
    { host = "nix-goldstar"; forwardAgent = true; }
  ];

  # Antigravity IDE rules — identical across all machines.
  # Reference as: modules.home.editors.antigravity = defaults.antigravity;
  antigravity = {
    rules = ''
      # Global Rules

      ## Communication
      - Respond in Russian unless the user writes in English
      - Direct, no fluff — answer immediately
      - Dense, iterative style

      ## User Profile
      - Expert: Linux, NixOS, kernel/C++, OSS, game optimization
      - Preferences: NixOS/Endeavour, gaming/streaming, DSLR photography
      - Regions of interest: Russia, Georgia

      ## Code Style
      - Comment non-obvious decisions
      - Cite sources when referencing external docs
      - Imperative mood in commit messages
    '';
    cavemanEnable = true;
  };
}
