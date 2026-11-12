# Debian (headless dev box) shell layer. Sourced by the shared zsh modules
# (aliases/exports/sources) through zsh/os/linux.zsh; the DOTFILES_OS guard
# makes it run once per shell. No pyenv, no nvm, no bun: mise is the toolchain.
[[ -n "$DOTFILES_OS" ]] && return

DOTFILES_OS=debian
OS=Debian
typeset -U PATH             # keep PATH deduped across every prepend

export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

# Debian ships each plugin as its own package directory under /usr/share
# (`/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh`), which is exactly
# the layout sources.zsh expects: <dir>/<plugin>/<plugin>.zsh.
ZSH_PLUGIN_DIRS=("/usr/share")
