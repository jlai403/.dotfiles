#
# Hooks and Suffix Aliases
#

# Constants
NL_BGREEN="\n\033[1;32m"
NC_NL="\033[0m\n"

function auto_ls_after_cd() {
  if command -v eza &> /dev/null; then
    eza -a
  else
    ls -a
  fi
}
chpwd_functions+=(auto_ls_after_cd)

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
