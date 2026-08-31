OS="$(uname -s)"
if [[ "$OS" == "Darwin" ]]; then
  source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
else
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Private/machine-local overrides (not tracked in public repo)
[[ -f ~/.dotfiles_private/zsh/private.zsh ]] && source ~/.dotfiles_private/zsh/private.zsh
