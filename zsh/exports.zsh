# Shared shell environment. Platform values (PATH, SSH_AUTH_SOCK,
# HOMEBREW_PREFIX, NVM_SH, ZSH_PLUGIN_DIRS) come from zsh/os/<os>.zsh.
_dots_os="$HOME/.dotfiles/zsh/os/${(L)$(uname -s)}.zsh"
[[ -f "$_dots_os" ]] && source "$_dots_os"
unset _dots_os

# Put pyenv shims first without duplicating them (the OS layer's `typeset -U PATH`
# also keeps repeated prepends deduped). Skipped where pyenv isn't installed: an
# empty PYENV_ROOT would otherwise prepend a literal /shims.
if [[ -n "${PYENV_ROOT:-}" ]]; then
  export PATH="$PYENV_ROOT/shims:${PATH//:$PYENV_ROOT\/shims/}"
fi

# Lazy loaders exist only where the tool does — a headless box runs neither.
if [[ -n "${PYENV_ROOT:-}" ]]; then
  load-pyenv() {
    # prevent re-sourcing
    unset -f pyenv
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
  }

  # load pyenv on first call
  pyenv() { load-pyenv; pyenv "$@"; }
fi

if [[ -s "${NVM_SH:-}" ]]; then
  load-nvm() {
    # prevent re-sourcing
    unset -f nvm node npm npx yarn pnpm
    [ -s "$NVM_SH" ] && \. "$NVM_SH"
    [ -n "${NVM_COMPLETION:-}" ] && [ -s "$NVM_COMPLETION" ] && \. "$NVM_COMPLETION"
  }

  # load nvm on first call
  nvm()  { load-nvm; nvm "$@"; }
  node() { load-nvm; node "$@"; }
  npm()  { load-nvm; npm "$@"; }
  npx()  { load-nvm; npx "$@"; }
  yarn() { load-nvm; yarn "$@"; }
  pnpm() { load-nvm; pnpm "$@"; }
fi
