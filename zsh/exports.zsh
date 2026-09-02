OS="$(uname -s)"
source ~/.dotfiles/zsh/op.zsh

case "$OS" in
  Darwin)
    export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

    _op_env SPOTIFY_CLIENT_ID 'op://Private/spotify keys/client_id' 86400

    export PYENV_ROOT="$HOME/.pyenv"
    export HOMEBREW_PREFIX=$(brew --prefix)
    export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PYENV_ROOT/opt/e2fsprogs/bin:$HOMEBREW_PREFIX/bin:/usr/bin:$PATH"
    export NVM_DIR="$HOME/.nvm"

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
      [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
      [ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion"
    }

    # load nvm on first call
    nvm()  { load-nvm; nvm "$@"; }
    node() { load-nvm; node "$@"; }
    npm()  { load-nvm; npm "$@"; }
    yarn() { load-nvm; yarn "$@"; }
    pnpm() { load-nvm; pnpm "$@"; }
    ;;
  Linux)
    export SSH_AUTH_SOCK=~/.1password/agent.sock
    export PYENV_ROOT="$HOME/.pyenv"
    export NVM_DIR="$HOME/.nvm"
    export PATH="$HOME/.local/bin:$HOME/.bun/bin:/usr/bin:$PATH"

    _op_env SPOTIFY_CLIENT_ID 'op://Private/spotify keys/client_id' 86400

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
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    }

    # load nvm on first call
    nvm()  { load-nvm; nvm "$@"; }
    node() { load-nvm; node "$@"; }
    npm()  { load-nvm; npm "$@"; }
    yarn() { load-nvm; yarn "$@"; }
    pnpm() { load-nvm; pnpm "$@"; }
    ;;
esac
