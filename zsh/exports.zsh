export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/usr/local/opt/e2fsprogs/bin:/usr/local/opt/e2fsprogs/sbin:~/Library/Python/3.6/bin:/usr/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
export HOMEBREW_PREFIX="/opt/homebrew"

eval "$(pyenv init --path)"
eval "$(pyenv init -)"

load-nvm() {
  # prevent re-sourcing
  unset -f nvm node npm yarn pnpm
  [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
  [ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion"
}

# load nvm on first call
nvm()  { load-nvm; nvm "$@"; }
node() { load-nvm; node "$@"; }
npm()  { load-nvm; npm "$@"; }
yarn() { load-nvm; yarn "$@"; }
pnpm() { load-nvm; pnpm "$@"; }
