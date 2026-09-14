#
# Hooks and Suffix Aliases
#

# Constants
NL_BGREEN="\n\033[1;32m"
NC_NL="\033[0m\n"

function auto_ls_after_cd() {
  if command -v eza &> /dev/null; then
    eza --icons --group-directories-first -a
  else
    ls -a
  fi
}
chpwd_functions+=(auto_ls_after_cd)

# Lazy mise activation: only activate when a project has mise config
_mise_lazy_activate() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.mise.toml" || -f "$dir/mise.toml" ]]; then
      # Found mise config — activate once, remove this hook
      add-zsh-hook -D precmd _mise_lazy_activate
      add-zsh-hook -D chpwd _mise_lazy_activate
      eval "$(mise activate zsh)"
      return
    fi
    dir="${dir:h}"
  done
}
chpwd_functions+=(_mise_lazy_activate)

function git() {
  command git "$@"
  local last_exit_code=$?

  if [[ $last_exit_code -eq 0 && "$1" == "checkout" ]]; then
    if [[ "$2" == "main" || "$2" == "master" ]]; then
      printf "${NL_BGREEN}✓ Checked out %s. Pulling latest changes...${NC_NL}" "$2"
      command git pull --prune
    fi
  fi
  return $last_exit_code
}
