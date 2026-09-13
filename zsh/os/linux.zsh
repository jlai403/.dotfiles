# Linux (Omarchy) shell layer. Sourced by the shared zsh modules
# (aliases/exports/sources) when present; the DOTFILES_OS guard makes it run
# once per shell.
[[ -n "$DOTFILES_OS" ]] && return

DOTFILES_OS=linux
OS=Linux
typeset -U PATH             # keep PATH deduped across every prepend

export PYENV_ROOT="$HOME/.pyenv"
export NVM_DIR="$HOME/.nvm"
export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
export NVM_SH="$NVM_DIR/nvm.sh"
export NVM_COMPLETION=""
export PATH="$HOME/.local/bin:$HOME/.bun/bin:/usr/bin:$PATH"

ZSH_PLUGIN_DIRS=("/usr/share/zsh/plugins")
