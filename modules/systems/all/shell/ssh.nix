# SSH agent configuration (system-level)
# Cross-platform system module (Linux + Darwin)
# Note: SSH client config is now in modules/home/shell/ssh/ssh.nix (user-level)
{ lib, config, system, ... }@args:

lib.my.mkSystemModuleV2 args {
  namespace = "all";
  description = "SSH agent configuration (system-level)";

  # Linux-only: start SSH agent system-wide (Darwin uses Keychain)
  moduleLinux = _: {
    programs.ssh.startAgent = true;

    # Enable all terminfo entries (including xterm-ghostty) to support
    # remote SSH clients that send custom TERM values (e.g., Ghostty terminal).
    # This prevents "can't find terminal definition" errors in set-environment.
    environment.enableAllTerminfo = true;
  };
}
