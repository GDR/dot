# Common zsh configuration
# This file is live-editable - changes take effect on new shell sessions

# Fix colors in SSH sessions — remote may lack terminfo for the client terminal
# (e.g. xterm-ghostty). Fall back to xterm-256color which is universally available.
[[ -n "$SSH_TTY" && ! -e "/usr/share/terminfo/${TERM[1]}/$TERM" && ! -e "$HOME/.terminfo/${TERM[1]}/$TERM" ]] && export TERM=xterm-256color

# Per-machine SOPS key wrapper with Bitwarden & 15-minute RAM caching
sops() {
  local host_name
  host_name="$(hostname -s)"
  local cache_file="/tmp/.sops-age-key-${host_name}-${UID}"
  local ttl=900  # 15 minutes TTL

  # 1. Check TTL expiration of cached file
  if [[ -f "$cache_file" ]]; then
    local now mtime age
    now=$(date +%s)
    if [[ "$OSTYPE" == "darwin"* ]]; then
      mtime=$(stat -f %m "$cache_file")
    else
      mtime=$(stat -c %Y "$cache_file")
    fi
    age=$(( now - mtime ))
    if (( age > ttl )); then
      rm -f "$cache_file"
      unset SOPS_AGE_KEY
    fi
  fi

  # 2. Load from RAM cache or query Bitwarden for per-machine key
  if [[ -z "$SOPS_AGE_KEY" ]]; then
    if [[ -f "$cache_file" ]]; then
      export SOPS_AGE_KEY="$(<"$cache_file")"
      touch "$cache_file"
    elif command -v bw >/dev/null 2>&1; then
      echo "==> Fetching SOPS key for '${host_name}' from Bitwarden..."
      local key
      key="$(bw get notes "SOPS Age Key ${host_name}" 2>/dev/null)"
      if [[ -n "$key" ]]; then
        export SOPS_AGE_KEY="$key"
        (umask 077 && echo "$key" > "$cache_file")
      fi
    fi
  fi

  command sops "$@"
}
