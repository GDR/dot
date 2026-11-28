# lazyworktree - TUI for managing Git worktrees
{ lib, ... }:

lib.my.mkFeature {
  description = "lazyworktree - TUI for managing Git worktrees";
  cascade = false;

  homeModule = {
    programs.lazyworktree = {
      enable = true;
      enableZshIntegration = false;
    };

    # Use --output-selection instead of HM's stdout capture so the TUI keeps a tty
    programs.zsh.initContent = ''
      lwt() {
        local tmp selected rc
        tmp=$(mktemp "''${TMPDIR:-/tmp}/lazyworktree.selection.XXXXXX") || return 1
        command lazyworktree --output-selection="$tmp" "$@"
        rc=$?
        if (( rc == 0 )) && [[ -s "$tmp" ]]; then
          selected=$(<"$tmp")
          [[ -n "$selected" && -d "$selected" ]] && cd "$selected"
        fi
        rm -f "$tmp"
        return $rc
      }
    '';
  };
}
