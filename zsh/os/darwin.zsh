# macOS shell layer. Sourced by the shared zsh modules (aliases/exports/sources)
# when present; the DOTFILES_OS guard makes it run once per shell.
[[ -n "$DOTFILES_OS" ]] && return

DOTFILES_OS=darwin
OS=Darwin
typeset -U PATH             # keep PATH deduped across every prepend

export PYENV_ROOT="$HOME/.pyenv"
export NVM_DIR="$HOME/.nvm"
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
export HOMEBREW_PREFIX="$(brew --prefix)"
export NVM_SH="$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
export NVM_COMPLETION="$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion"
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PYENV_ROOT/opt/e2fsprogs/bin:$HOMEBREW_PREFIX/bin:/usr/bin:$PATH"

ZSH_PLUGIN_DIRS=("$HOMEBREW_PREFIX/share")

# macOS-only aliases
alias borders-start='nohup borders active_color=0xff00cfe6 inactive_color=0xff494d64 width=4.0 > /dev/null 2>&1 &'
alias findlock="ioreg -l -w 0 | grep SecureInput"
