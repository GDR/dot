# macOS system profile — standard Darwin system setup
# homebrew.user and openssh.userMap are user-specific; set them in the host via
# lib.recursiveUpdate profiles.system.darwin { homebrew.user = "..."; ... }
{
  system.darwin = {
    macos-settings.enable = true;
    app-aliases.enable = true;
  };
}
