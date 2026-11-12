# Linux shell layer. Sourced by the shared zsh modules (aliases/exports/sources)
# when present. `uname -s` is Linux for every distro, so this file dispatches:
# Arch/Omarchy continues below, anything else (Debian) gets its own layer.
if ! grep -qE '^ID="?(arch|omarchy)"?' /etc/os-release 2>/dev/null; then
  source "$HOME/.dotfiles/zsh/os/debian.zsh"
  return
fi

# Arch (Omarchy). The DOTFILES_OS guard makes it run once per shell.
[[ -n "$DOTFILES_OS" ]] && return

DOTFILES_OS=linux
OS=Linux
typeset -U PATH             # keep PATH deduped across every prepend

export PYENV_ROOT="$HOME/.pyenv"
export NVM_DIR="$HOME/.nvm"
# Claim the 1Password socket unless an agent socket is already inherited
# (e.g. ssh agent forwarding on headless boxes — don't clobber it)
if [[ ! ( -e "${SSH_AUTH_SOCK:-}" ) && -e "$HOME/.1password/agent.sock" ]]; then
  export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
fi
export NVM_SH="$NVM_DIR/nvm.sh"
export NVM_COMPLETION=""
export PATH="$HOME/.local/bin:$HOME/.bun/bin:/usr/bin:$PATH"

ZSH_PLUGIN_DIRS=("/usr/share/zsh/plugins")
