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
    fi
  fi

  # 2. Load from per-user cache or query Bitwarden for per-machine key
  # Never export SOPS_AGE_KEY into the parent interactive shell; pass only to child sops.
  local age_key="${SOPS_AGE_KEY-}"
  if [[ -z "$age_key" ]]; then
    if [[ -f "$cache_file" && ! -L "$cache_file" ]]; then
      age_key="$(<"$cache_file")"
      touch -h "$cache_file"
    elif command -v bw >/dev/null 2>&1; then
      echo "==> Fetching SOPS key for '${host_name}' from Bitwarden..."
      local key
      key="$(bw get notes "SOPS Age Key ${host_name}" 2>/dev/null)"
      if [[ -n "$key" ]]; then
        age_key="$key"
        (set -C; umask 077; rm -f "$cache_file" && printf '%s\n' "$key" > "$cache_file")
      fi
    fi
  fi

  if [[ -n "$age_key" ]]; then
    SOPS_AGE_KEY="$age_key" command sops "$@"
  else
    command sops "$@"
  fi
}

# Session-scoped ephemeral nixpkgs PATH management (nadd / nls / nrm / nclear)
typeset -ga _NADD_PKGS=()

_nadd_apply() {
  if (( ${#_NADD_PKGS} == 0 )); then
    if [[ -n "${_NADD_BASE_PATH+x}" ]]; then
      export PATH="$_NADD_BASE_PATH"
      unset _NADD_BASE_PATH
      rehash
    fi
    return 0
  fi
  local new_path
  new_path="$(PATH="$_NADD_BASE_PATH" nix-shell -p "${_NADD_PKGS[@]}" --run 'printf "%s" "$PATH"')" || return $?
  export PATH="$new_path"
  rehash
}

nadd() {
  if (( $# == 0 )); then
    echo "Usage: nadd <pkg> [pkg...]" >&2
    return 1
  fi
  [[ -z "${_NADD_BASE_PATH+x}" ]] && _NADD_BASE_PATH="$PATH"
  local -a prev=("${_NADD_PKGS[@]}")
  local pkg
  for pkg in "$@"; do
    (( ${_NADD_PKGS[(Ie)$pkg]} )) || _NADD_PKGS+=("$pkg")
  done
  if ! _nadd_apply; then
    _NADD_PKGS=("${prev[@]}")
    (( ${#_NADD_PKGS} == 0 )) && unset _NADD_BASE_PATH
    return 1
  fi
}

nls() {
  if (( ${#_NADD_PKGS} == 0 )); then
    echo "No active nadd packages."
    return 0
  fi
  printf '%s\n' "${_NADD_PKGS[@]}"
}

nrm() {
  if (( $# == 0 )); then
    echo "Usage: nrm <pkg> [pkg...]" >&2
    return 1
  fi
  local -a remaining=()
  local pkg
  for pkg in "${_NADD_PKGS[@]}"; do
    (( ${argv[(Ie)$pkg]} )) || remaining+=("$pkg")
  done
  _NADD_PKGS=("${remaining[@]}")
  _nadd_apply
}

nclear() {
  _NADD_PKGS=()
  _nadd_apply
}

_nrm() {
  local -a candidates=()
  local pkg
  for pkg in "${_NADD_PKGS[@]}"; do
    (( ${words[2,-1][(Ie)$pkg]} )) || candidates+=("$pkg")
  done
  _describe 'active nadd package' candidates
}
(( $+functions[compdef] )) && compdef _nrm nrm
