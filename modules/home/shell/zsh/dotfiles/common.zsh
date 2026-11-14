# Common zsh configuration
# This file is live-editable - changes take effect on new shell sessions

# Fix colors in SSH sessions — remote may lack terminfo for the client terminal
# (e.g. xterm-ghostty). Fall back to xterm-256color which is universally available.
[[ -n "$SSH_TTY" && ! -e "/usr/share/terminfo/${TERM[1]}/$TERM" && ! -e "$HOME/.terminfo/${TERM[1]}/$TERM" ]] && export TERM=xterm-256color

# Per-machine SOPS key wrapper with Bitwarden & 15-minute local caching.
# Prefers XDG_RUNTIME_DIR (Linux /run/user/$UID 0700 tmpfs) or per-user TMPDIR
# (macOS /var/folders/... 0700), falling back to ~/.cache/sops (0700) if neither
# is set to a user-owned 0700 directory (e.g. when TMPDIR=/tmp).
sops() {
  zmodload -F zsh/stat b:zstat

  local host_name
  host_name="$(hostname -s)"

  local cache_dir="${XDG_RUNTIME_DIR:-${TMPDIR%/}}"
  if [[ -z "$cache_dir" || ! -d "$cache_dir" || -L "$cache_dir" || ! -O "$cache_dir" ]] \
    || (( ($(zstat +mode "$cache_dir") & 8#077) != 0 )); then
    cache_dir="$HOME/.cache/sops"
    mkdir -p -m 700 "$cache_dir"
    chmod 700 "$cache_dir"
  fi

  local cache_file="${cache_dir}/sops-age-key-${host_name}"
  local ttl=900  # 15 minutes TTL

  # 1. Check TTL expiration of cached file (reject symlinks)
  if [[ -L "$cache_file" ]]; then
    rm -f "$cache_file"
  elif [[ -f "$cache_file" ]]; then
    local now mtime age
    now=$(date +%s)
    mtime=$(zstat +mtime "$cache_file")
    age=$(( now - mtime ))
    if (( age > ttl )); then
      rm -f "$cache_file"
      unset SOPS_AGE_KEY
    fi
  fi

  # 2. Load from per-user cache or query Bitwarden for per-machine key
  if [[ -z "$SOPS_AGE_KEY" ]]; then
    if [[ -f "$cache_file" && ! -L "$cache_file" ]]; then
      export SOPS_AGE_KEY="$(<"$cache_file")"
      touch -h "$cache_file"
    elif command -v bw >/dev/null 2>&1; then
      echo "==> Fetching SOPS key for '${host_name}' from Bitwarden..."
      local key
      key="$(bw get notes "SOPS Age Key ${host_name}" 2>/dev/null)"
      if [[ -n "$key" ]]; then
        export SOPS_AGE_KEY="$key"
        (set -C; umask 077; rm -f "$cache_file" && printf '%s\n' "$key" > "$cache_file")
      fi
    fi
  fi

  command sops "$@"
}
