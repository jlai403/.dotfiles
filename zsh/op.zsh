# op-backed env secrets: Keychain cache (macOS), bootstrapped from 1Password.
# Usage: _op_env <VAR> <keychain-service> <op://reference> [ttl_seconds]
#   ttl_seconds > 0 re-reads op when the Keychain entry is older than TTL.
#   Rotate/force-refresh: op-env-reset <keychain-service> then open a new shell.
#   Linux (no `security` CLI): value is resolved from op on each shell; no cache.

_op_env() {
  local var="$1" svc="$2" ref="$3" ttl="${4:-0}" val created age

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
  # op-env-reset <keychain-service> [<keychain-service> ...]
  local svc rc=0
  for svc in "$@"; do
    security delete-generic-password -s "$svc" -a "$USER" >/dev/null 2>&1 \
      && echo "cleared $svc" \
      || { echo "no entry for $svc"; rc=1; }
  done
  return $rc
}
