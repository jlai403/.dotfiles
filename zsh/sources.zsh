# Shared plugin loading. ZSH_PLUGIN_DIRS is set per-OS in zsh/os/<os>.zsh.
_dots_os="$HOME/.dotfiles/zsh/os/${(L)$(uname -s)}.zsh"
[[ -f "$_dots_os" ]] && source "$_dots_os"
unset _dots_os

for _dir in $ZSH_PLUGIN_DIRS; do
  [[ -f "$_dir/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] \
    && source "$_dir/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -f "$_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] \
    && source "$_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
done
unset _dir

# Private/machine-local overrides (not tracked in public repo)
[[ -f ~/.dotfiles_private/zsh/private.zsh ]] && source ~/.dotfiles_private/zsh/private.zsh
