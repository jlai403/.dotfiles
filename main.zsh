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

git submodule update --recursive --remote
echo "${YELLOW}Update submodules ${NC}"

#################################
# install brew app
#################################
if [[ "$UPDATE_APPS" == "true" ]]; then
  _update_apps
  bun add -g btca
  brew install pipx
  pipx upgrade-all 2>/dev/null || pipx install code-review-graph
  code-review-graph install
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

_stow stow
_stow aerospace
_stow borders
mkdir -p ~/.local/bin
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
  BINARY_NAME="borders-arm64"
else
  BINARY_NAME="borders-x86_64"
fi
cp "${DOTS_DIR}/borders/bin/${BINARY_NAME}" ~/.local/bin/borders
chmod +x ~/.local/bin/borders
echo "${GREEN}Installed vendored borders binary to ~/.local/bin/borders (${ARCH})${NC}"
_stow ghostty
_stow git
_stow nvim
_stow tmux
  _stow zed
  _stow starship
_stow television

echo "${YELLOW}Linking global agent rules...${NC}"
mkdir -p ~/.claude
mkdir -p ~/.config/opencode
mkdir -p ~/.gemini
ln -sf "$(pwd)/global-agent-rules.md" ~/.claude/CLAUDE.md
ln -sf "$(pwd)/global-agent-rules.md" ~/.config/opencode/AGENTS.md
ln -sf "$(pwd)/global-agent-rules.md" ~/.gemini/AGENTS.md
ln -sf "$(pwd)/global-agent-rules.md" ~/.gemini/GEMINI.md

echo "${YELLOW}Updating skills submodules...${NC}"
git submodule update --recursive --remote --init skills/superpowers skills/excalidraw-diagram skills/duckdb-skills skills/caveman skills/code-review-graph

echo "${YELLOW}Linking skills to claude code...${NC}"
rm -rf ~/.claude/skills
mkdir -p ~/.claude/skills
ln -sf "$(pwd)/skills/superpowers/skills/"* ~/.claude/skills/
ln -sf "$(pwd)/skills/code-review-graph/skills/"* ~/.claude/skills/

echo "${YELLOW}Linking skills to gemini...${NC}"
# Antigravity (legacy)
rm -rf ~/.gemini/antigravity/skills
mkdir -p ~/.gemini/antigravity/skills
ln -sf "$(pwd)/skills/superpowers/skills/"* ~/.gemini/antigravity/skills/
mkdir -p ~/.gemini/antigravity/skills/excalidraw-diagram
ln -sf "$(pwd)/skills/excalidraw-diagram/SKILL.md" ~/.gemini/antigravity/skills/excalidraw-diagram/SKILL.md
ln -sf "$(pwd)/skills/duckdb-skills/skills/"* ~/.gemini/antigravity/skills/
mkdir -p ~/.gemini/antigravity/skills/notion-cli
ln -sf "$(pwd)/skills/notion-cli/SKILL.md" ~/.gemini/antigravity/skills/notion-cli/SKILL.md
ln -sf "$(pwd)/skills/code-review-graph/skills/"* ~/.gemini/antigravity/skills/

# Gemini CLI (Official)
rm -rf ~/.gemini/skills
mkdir -p ~/.gemini/skills
ln -sf "$(pwd)/skills/duckdb-skills/skills/"* ~/.gemini/skills/
ln -sf "$(pwd)/skills/excalidraw-diagram" ~/.gemini/skills/excalidraw-diagram
ln -sf "$(pwd)/skills/code-review-graph/skills/"* ~/.gemini/skills/

rm -rf ~/.gemini/extensions
mkdir -p ~/.gemini/extensions
ln -sf "$(pwd)/skills/superpowers" ~/.gemini/extensions/superpowers


echo "${YELLOW}Linking skills to opencode...${NC}"
rm -rf ~/.config/opencode/skills
mkdir -p ~/.config/opencode/skills
ln -sf "$(pwd)/skills/excalidraw-diagram" ~/.config/opencode/skills/excalidraw-diagram
ln -sf "$(pwd)/skills/duckdb-skills/skills/"* ~/.config/opencode/skills/
mkdir -p ~/.config/opencode/skills/notion-cli
ln -sf "$(pwd)/skills/notion-cli/SKILL.md" ~/.config/opencode/skills/notion-cli/SKILL.md
ln -sf "$(pwd)/skills/caveman/skills/caveman" ~/.config/opencode/skills/caveman
ln -sf "$(pwd)/skills/caveman/skills/caveman-commit" ~/.config/opencode/skills/caveman-commit
ln -sf "$(pwd)/skills/caveman/skills/caveman-review" ~/.config/opencode/skills/caveman-review
ln -sf "$(pwd)/skills/caveman/skills/caveman-help" ~/.config/opencode/skills/caveman-help
ln -sf "$(pwd)/skills/caveman/skills/compress" ~/.config/opencode/skills/compress
ln -sf "$(pwd)/skills/code-review-graph/skills/"* ~/.config/opencode/skills/

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

if [[ "$CONFIGURE_OSX" == "true" ]]; then
  _configure_osx
fi

