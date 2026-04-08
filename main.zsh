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

echo "${BBLUE}"
cat << 'EOF'
       _  __        _          __        __   ____ _  __           
      (_)/ /____ _ (_)    ____/ /____   / /_ / __/(_)/ /___   _____
     / // // __ `// /    / __  // __ \ / __// /_ / // // _ \ / ___/
    / // // /_/ // /  _ / /_/ // /_/ // /_ / __// // //  __/(__  ) 
 __/ //_/ \__,_//_/  (_)\__,_/ \____/ \__//_/  /_//_/ \___//____/  
/___/
EOF
echo "${NC}"
echo ""

DOTS_DIR="$(pwd)"
PRIVATE_DOTS_DIR="$(pwd)/../.dotfiles_private"

_configure_osx() {
  source "$(pwd)/macos/defaults.zsh"
  configure_macos_defaults
}

_update_apps() {
  echo "${BGREEN}Installing Brew apps...${NC}"
  brew bundle install
}

_stow() {
  stow -v ${1}
  echo "${GREEN}Symlink updated for ${1}${NC}"
}

_zen_profile_dir() {
  local base=~/Library/Application\ Support/zen
  local rel=$(awk -F= '/^\[Install/{f=1} f && /^Default=/{print $2; exit}' "${base}/profiles.ini")
  if [[ -z "$rel" ]]; then
    echo "${RED}Error: could not resolve Zen profile from profiles.ini${NC}" >&2
    return 1
  fi
  echo "${base}/${rel}/"
}

_zen_backup() {
  local profile
  profile=$(_zen_profile_dir) || return 1
  local files=(zen-keyboard-shortcuts.json zen-themes.json containers.json)
  mkdir -p "${DOTS_DIR}/zen"
  for f in $files; do
    if cp "${profile}${f}" "${DOTS_DIR}/zen/${f}"; then
      echo "${GREEN}Backed up ${f}${NC}"
    else
      echo "${RED}Failed to back up ${f}${NC}"
    fi
  done
  echo "${BGREEN}Zen config backed up to dotfiles${NC}"
}

_zen_restore() {
  local profile
  profile=$(_zen_profile_dir) || return 1
  mkdir -p "${profile}"
  local files=(zen-keyboard-shortcuts.json zen-themes.json containers.json)
  for f in $files; do
    if [[ ! -f "${DOTS_DIR}/zen/${f}" ]]; then
      echo "${YELLOW}Skipping ${f} — not found in dotfiles${NC}"
      continue
    fi
    cp "${DOTS_DIR}/zen/${f}" "${profile}${f}"
    echo "${GREEN}Restored ${f}${NC}"
  done
  echo "${BGREEN}Zen config restored to profile${NC}"
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
    --zen-backup)
      ZEN_BACKUP=true
      shift
      ;;
    --zen-restore)
      ZEN_RESTORE=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

git submodule update --recursive
echo "${YELLOW}Update submodules ${NC}"

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
# Load starship
eval "$(starship init zsh)"
' >> ~/.zshrc
  echo "${GREEN}Added starship prompt to ~/.zshrc ${NC}"
else
  echo "${YELLOW}Starship prompt already in ~/.zshrc ${NC}"
fi

if ! grep -q 'eval "$(zoxide init zsh)"' ~/.zshrc; then
  echo '
# Load zoxide
eval "$(zoxide init zsh)"
' >> ~/.zshrc
  echo "${GREEN}Added zoxide to ~/.zshrc ${NC}"
else
  echo "${YELLOW}zoxide already in ~/.zshrc ${NC}"
fi

if ! grep -q 'eval "$(mise activate zsh)"' ~/.zshrc; then
  echo '
# Load mise
eval "$(mise activate zsh)"
' >> ~/.zshrc
  echo "${GREEN}Added mise to ~/.zshrc ${NC}"
else
  echo "${YELLOW}mise already in ~/.zshrc ${NC}"
fi

#################################
# update dotfiles via symlinks
#################################

_stow aerospace
_stow borders
_stow ghostty
_stow git
_stow nvim
_stow tmux
_stow starship
_stow television

brew services start borders

echo "${YELLOW}Linking global agent rules...${NC}"
mkdir -p ~/.claude
mkdir -p ~/.config/opencode
mkdir -p ~/.gemini
ln -sf "$(pwd)/global-agent-rules.md" ~/.claude/CLAUDE.md
ln -sf "$(pwd)/global-agent-rules.md" ~/.config/opencode/AGENTS.md
ln -sf "$(pwd)/global-agent-rules.md" ~/.gemini/AGENTS.md

echo "${YELLOW}Updating skills submodules...${NC}"
git submodule update --recursive --init skills/superpowers skills/excalidraw-diagram skills/duckdb-skills

echo "${YELLOW}Linking skills to gemini...${NC}"
rm -rf ~/.gemini/antigravity/skills
mkdir -p ~/.gemini/antigravity/skills
ln -sf "$(pwd)/skills/superpowers/skills/"* ~/.gemini/antigravity/skills/
mkdir -p ~/.gemini/antigravity/skills/excalidraw-diagram
ln -sf "$(pwd)/skills/excalidraw-diagram/SKILL.md" ~/.gemini/antigravity/skills/excalidraw-diagram/SKILL.md
ln -sf "$(pwd)/skills/duckdb-skills/skills/"* ~/.gemini/antigravity/skills/


echo "${YELLOW}Linking skills to opencode...${NC}"
rm -rf ~/.config/opencode/skills
mkdir -p ~/.config/opencode/skills/excalidraw-diagram
ln -sf "$(pwd)/skills/excalidraw-diagram/SKILL.md" ~/.config/opencode/skills/excalidraw-diagram/SKILL.md
ln -sf "$(pwd)/skills/duckdb-skills/skills/"* ~/.config/opencode/skills/

_stow opencode
_stow gemini

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
  if [ -f "$PRIVATE_DOTS_DIR/main.zsh" ]; then
    echo "${YELLOW}Running private dotfiles setup...${NC}"
    source "$PRIVATE_DOTS_DIR/main.zsh"
  fi
  cd $DOTS_DIR
fi

#################################
# Run OSX configuration if requested
#################################

desktoppr "$(pwd)/wallpaper/tokyo-night.jpg"

if [[ "$ZEN_BACKUP" == "true" && "$ZEN_RESTORE" == "true" ]]; then
  echo "${RED}Error: --zen-backup and --zen-restore are mutually exclusive${NC}" >&2
  exit 1
fi

[[ "$ZEN_BACKUP" == "true" ]] && _zen_backup
[[ "$ZEN_RESTORE" == "true" ]] && _zen_restore

if [[ "$CONFIGURE_OSX" == "true" ]]; then
  _configure_osx
fi

