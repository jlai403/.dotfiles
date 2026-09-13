# Shared shell environment. Platform values (PATH, SSH_AUTH_SOCK,
# HOMEBREW_PREFIX, NVM_SH, ZSH_PLUGIN_DIRS) come from zsh/os/<os>.zsh.
_dots_os="$HOME/.dotfiles/zsh/os/${(L)$(uname -s)}.zsh"
[[ -f "$_dots_os" ]] && source "$_dots_os"
unset _dots_os

# Put pyenv shims first without duplicating them (the OS layer's `typeset -U PATH`
# also keeps repeated prepends deduped).
export PATH="$PYENV_ROOT/shims:${PATH//:$PYENV_ROOT\/shims/}"

load-pyenv() {
  # prevent re-sourcing
  unset -f pyenv
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
}

# load pyenv on first call
pyenv() { load-pyenv; pyenv "$@"; }

load-nvm() {
  # prevent re-sourcing
  unset -f nvm node npm yarn pnpm
  [ -s "$NVM_SH" ] && \. "$NVM_SH"
  [ -n "$NVM_COMPLETION" ] && [ -s "$NVM_COMPLETION" ] && \. "$NVM_COMPLETION"
}

# load nvm on first call
nvm()  { load-nvm; nvm "$@"; }
node() { load-nvm; node "$@"; }
npm()  { load-nvm; npm "$@"; }
yarn() { load-nvm; yarn "$@"; }
pnpm() { load-nvm; pnpm "$@"; }
