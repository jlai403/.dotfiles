# zsh-compat overrides for Omarchy bash functions that use 0-based array indexing.
# tsl (tmux swarm) and hsl (herdr swarm) originally run under bash semantics, which
# breaks in zsh's 1-based-arrays-by-default. We re-run the Omarchy-bundled bodies
# under `emulate -L bash` (scoped to the function, restored on return).
# Only active when Omarchy's fns are present; no-op on macOS.
if typeset -f tsl >/dev/null 2>&1; then
  _omarchy_tsl_orig="$functions[tsl]"
  unfunction tsl
  tsl() {
    emulate -L bash
    eval "$_omarchy_tsl_orig"
  }
fi

if typeset -f hsl >/dev/null 2>&1; then
  _omarchy_hsl_orig="$functions[hsl]"
  unfunction hsl
  hsl() {
    emulate -L bash
    eval "$_omarchy_hsl_orig"
  }
fi
