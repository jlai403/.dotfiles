# op-backed env secrets: Keychain cache (macOS), bootstrapped from 1Password.
# Usage: _op_env <VAR> <op://reference> [ttl_seconds]
#   Service name is derived as "$_OP_NS/$VAR" for a uniform, greppable namespace.
#   ttl_seconds > 0 re-reads op when the Keychain entry is older than TTL.
#   Rotate/force-refresh: op-env-reset <VAR> then open a new shell.
#   Linux (no `security` CLI): value is resolved from op on each shell; no cache.

_OP_NS="dotfiles/cache/op_env"

_op_env() {
  local var="$1" ref="$2" ttl="${3:-0}" svc="$_OP_NS/$1" val created age

  if [[ "$(uname -s)" != "Darwin" ]]; then
    # No `security` CLI: resolve from 1Password each shell, no cache.
    [[ -x "$(command -v op)" ]] && export "$var"="$(op read "$ref" 2>/dev/null)"
    return 0
  fi

  if (( ttl > 0 )); then
    # Age check against the Keychain entry's cdat (created-at); refresh when stale.
    created="$(security find-generic-password -s "$svc" -a "$USER" 2>/dev/null \
               | command grep -oE '"20[0-9]{12}Z' | tr -d '"' | head -1)"
    if [[ -n "$created" ]]; then
      age=$(( $(date +%s) - $(date -u -j -f '%Y%m%d%H%M%S' "${created%Z}" +%s) ))
      (( age >= ttl )) && security delete-generic-password -s "$svc" -a "$USER" 2>/dev/null
    fi
  fi

  val="$(security find-generic-password -s "$svc" -a "$USER" -w 2>/dev/null)"
  if [[ -z "$val" && -x "$(command -v op)" ]]; then
    val="$(op read "$ref" 2>/dev/null)"
    [[ -n "$val" ]] && security add-generic-password -U -s "$svc" -a "$USER" -w "$val" >/dev/null 2>&1
  fi
  [[ -n "$val" ]] && export "$var"="$val"
}

op-env-reset() {
  # op-env-reset <VAR> [<VAR> ...]  |  op-env-reset --all
  local rc=0 arg

  if [[ "$1" == "--all" ]]; then
    for arg in $(security dump-keychain 2>/dev/null \
                 | command grep -oE "$_OP_NS/[A-Za-z0-9_]+" | sort -u); do
      security delete-generic-password -s "$arg" -a "$USER" >/dev/null 2>&1
      echo "cleared ${arg#$_OP_NS/}"
    done
    return 0
  fi

  for arg in "$@"; do
    security delete-generic-password -s "$_OP_NS/$arg" -a "$USER" >/dev/null 2>&1 \
      && echo "cleared $arg" \
      || { echo "no entry for $arg"; rc=1; }
  done
  return $rc
}
