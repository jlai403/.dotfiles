export PATH=/usr/local/opt/e2fsprogs/bin:/usr/local/opt/e2fsprogs/sbin:~/Library/Python/3.6/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:$PATH
export NVM_DIR="$HOME/.nvm"

load-nvm() {
  # prevent re-sourcing
  unset -f nvm node npm yarn pnpm
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}

# load nvm on first call
nvm()  { load-nvm; nvm "$@"; }
node() { load-nvm; node "$@"; }
npm()  { load-nvm; npm "$@"; }
yarn() { load-nvm; yarn "$@"; }
pnpm() { load-nvm; pnpm "$@"; }
