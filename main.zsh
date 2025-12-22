#!/usr/bin/env zsh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BRED='\033[1;31m'
BGREEN='\033[1;32m'
BYELLOW='\033[1;33m'
BBLUE='\033[1;34m'
NC='\033[0m' # No Color

DOTS_DIR="$(pwd)"
PRIVATE_DOTS_DIR="$(pwd)/../.dotfiles_private"

_configure_osx() {
  echo "${BGREEN}Configuring OSX settings...${NC}"
  # enable press and hold for special characters in VSCode
  defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
  defaults write com.google.antigravity ApplePressAndHoldEnabled -bool false

  # reduce motion when switching desktops
  sudo defaults write com.apple.universalaccess reduceMotion -bool true && killall Dock
  echo "${GREEN}OSX settings configured${NC}"
}

_update_apps() {
  echo "${BGREEN}Installing Brew apps...${NC}"
  brew bundle install
}

_stow() {
  stow -v ${1}
  echo "${GREEN}Symlink updated for ${1}${NC}"
}

#################################
# script start
#################################

# Parse arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --osx)
      CONFIGURE_OSX=true
      shift
      ;;
    --apps)
      UPDATE_APPS=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

#################################
# install brew app
#################################
if [[ "$UPDATE_APPS" == "true" ]]; then
  _update_apps
  bun add -g btca
fi

#################################
# update .zshrc
#################################
echo "${BGREEN}Updating .zshrc...${NC}"

if ! grep -q '# Load .dotfiles zsh configs' ~/.zshrc; then
  echo '
# Load .dotfiles zsh configs
for config in ~/.dotfiles/zsh/*.zsh; do
  source "$config"
done
' >> ~/.zshrc
  echo "${GREEN}Added .dotfile extensions to ~/.zshrc ${NC}"
else
  echo "${YELLOW}.dotfile extensions already in ~/.zshrc ${NC}"
fi

if ! grep -q 'eval "$(starship init zsh)"' ~/.zshrc; then
  echo '
# Load starship prompt
eval "$(starship init zsh)"
' >> ~/.zshrc
  echo "${GREEN}Added starship prompt to ~/.zshrc ${NC}"
else
  echo "${YELLOW}Starship prompt already in ~/.zshrc ${NC}"
fi

if ! grep -q 'eval "$(zoxide init zsh)"' ~/.zshrc; then
  echo '
# Load starship prompt
eval "$(zoxide init zsh)"
' >> ~/.zshrc
  echo "${GREEN}Added zoxide to ~/.zshrc ${NC}"
else
  echo "${YELLOW}zoxide already in ~/.zshrc ${NC}"
fi

#################################
# update dotfiles via symlinks
#################################

_stow aerospace
_stow ghostty
_stow git
_stow nvim
_stow tmux
_stow starship

# ssh
mkdir -p ~/.ssh

# Only add Includes if not already present
ssh_config_appends=$(cat $(pwd)/ssh/config.append)
if ! grep -q "${ssh_config_appends}" ~/.ssh/config; then
  ssh_backup_file="~/.ssh/config.bak_$(date '+%Y%m%d')"
  cp ~/.ssh/config ${ssh_backup_file}
  echo "created backup of ~/.ssh/config -> ${ssh_backup_file}"

  tmpfile=$(mktemp)
  echo "${ssh_config_appends}" > "${tmpfile}"
  [ -f ~/.ssh/config ] && cat ~/.ssh/config >> "${tmpfile}"
  mv $tmpfile ~/.ssh/config
  echo "${GREEN}Added SSH Includes to ~/.ssh/config${NC}"
else
  echo "${YELLOW}SSH Includes already present in ~/.ssh/config ${NC}"
fi

_stow ssh

if [ -d $PRIVATE_DOTS_DIR ]; then
    echo "Symlinking private dotfiles ssh"
    cd $PRIVATE_DOTS_DIR && _stow ssh
    cd $DOTS_DIR
fi

#################################
# Run OSX configuration if requested
#################################

desktoppr "$(pwd)/wallpaper/tokyo-night.jpg"

if [[ "$CONFIGURE_OSX" == "true" ]]; then
  _configure_osx
fi

