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
OS="$(uname -s)"

_configure_osx() {
  source "$(pwd)/macos/system/defaults.zsh"
  configure_macos_defaults
}

_update_apps() {
  echo "${BGREEN}Installing Brew apps...${NC}"
  brew bundle install
}

_install_linux_apps() {
  local pkgfile="${DOTS_DIR}/omarchy/Pkgfile"
  if [[ ! -f "$pkgfile" ]]; then
    echo "${RED}Missing package list: ${pkgfile}${NC}"
    return 1
  fi
  local pkgs=(${(f)"$(grep -vE '^\s*(#|$)' "$pkgfile")"})

  if ! command -v yay >/dev/null 2>&1; then
    echo "${YELLOW}yay not found, installing via pacman...${NC}"
    sudo pacman -S --needed --noconfirm yay
  fi

  echo "${BGREEN}Installing Linux apps via yay: ${pkgs[*]}${NC}"
  yay -S --needed --noconfirm --answerdiff None --answerclean None "${pkgs[@]}"

  if [[ -x /usr/bin/zsh && "$(basename "$SHELL")" != "zsh" ]]; then
    echo "${YELLOW}Set zsh as your default shell:  chsh -s /usr/bin/zsh${NC}"
  fi
}

_install_omarchy_plugins() {
  local yaml="${DOTS_DIR}/omarchy/plugins.yml"
  if ! command -v omarchy >/dev/null 2>&1; then
    echo "${YELLOW}omarchy CLI not found, skipping plugins${NC}"
    return 0
  fi
  if [[ ! -f "$yaml" ]]; then
    echo "${RED}Missing plugin manifest: ${yaml}${NC}"
    return 1
  fi
  if ! command -v yq >/dev/null 2>&1; then
    echo "${YELLOW}yq not found, skipping omarchy plugins${NC}"
    return 0
  fi

  local urls=("${(@f)"$(yq '.plugins[].url' "$yaml")"}")
  local enables=("${(@f)"$(yq '.plugins[].enable // "false"' "$yaml")"}")

  for i in {1..${#urls}}; do
    local url="$urls[i]"
    local name="${url:t:r}"
    if [[ -d "$HOME/.config/omarchy/plugins/$name" ]]; then
      echo "${YELLOW}omarchy plugin ${name} already installed, skipping${NC}"
      continue
    fi
    local args=(add "$url")
    [[ "${enables[i]}" == "true" ]] && args+=(--enable)
    omarchy plugin "${args[@]}" --yes 2>/dev/null \
      || echo "${RED}failed to add omarchy plugin ${url}${NC}"
  done
}

_stow() {
  stow -v ${1}
  echo "${GREEN}Symlink updated for ${1}${NC}"
}

_stow_group() {
  local dir="$1" pkg="$2"
  stow -v -d "${DOTS_DIR}/${dir}" -t ~ "$pkg"
  echo "${GREEN}Symlink updated for ${pkg} (${dir})${NC}"
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
    --linux-apps)
      UPDATE_LINUX_APPS=true
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
if [[ "$UPDATE_APPS" == "true" && "$OS" == "Darwin" ]]; then
  _update_apps
  bun add -g btca
  brew install pipx
  pipx upgrade-all 2>/dev/null
fi

if [[ "$UPDATE_LINUX_APPS" == "true" && "$OS" == "Linux" ]]; then
  _install_linux_apps
fi

if [[ "$OS" == "Linux" ]] && command -v mise >/dev/null 2>&1; then
  echo "${YELLOW}Installing mise-managed tools...${NC}"
  mise install
  echo "${GREEN}Mise tools installed${NC}"
fi

# Tailscale: reject tailnet subnet routes so home-LAN IPs always use the local
# router path; the subnet router (alpine-caddy) stays reachable via its 100.x IP
if [[ "$OS" == "Linux" ]]; then
  if ! command -v tailscale >/dev/null 2>&1; then
    echo "${YELLOW}Tailscale: skipped (not installed)${NC}"
  elif tailscale set --accept-routes=false 2>/dev/null || sudo -n tailscale set --accept-routes=false 2>/dev/null; then
    echo "${GREEN}Tailscale: accept-routes=false${NC}"
  else
    echo "${YELLOW}Tailscale: could not apply (service inactive? run: sudo tailscale set --accept-routes=false)${NC}"
  fi
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

#################################
# update dotfiles via symlinks
#################################

# Real config dirs keep stow from folding ~/.config/<app> into the repo
# (a folded dir would capture app-written logs/state into the dotfiles tree).
mkdir -p ~/.config/ghostty ~/.config/cliamp

if [[ "$OS" == "Darwin" ]]; then
  _stow_group macos aerospace
  _stow_group macos borders
  mkdir -p ~/.local/bin
  ARCH=$(uname -m)
  if [[ "$ARCH" == "arm64" ]]; then
    BINARY_NAME="borders-arm64"
  else
    BINARY_NAME="borders-x86_64"
  fi
  cp "${DOTS_DIR}/macos/borders/bin/${BINARY_NAME}" ~/.local/bin/borders
  chmod +x ~/.local/bin/borders
  echo "${GREEN}Installed vendored borders binary to ~/.local/bin/borders (${ARCH})${NC}"
  # Ghostty: shared base config (root pkg) + macOS overrides in local.conf
  _stow_group macos ghostty
fi
_stow cliamp
_stow ghostty
_stow git
_stow nvim
stow -v --no-folding herdr && echo "${GREEN}Symlink updated for herdr${NC}"
_stow inputrc
_stow tmux
mkdir -p ~/.local/bin
_stow zed
_stow television

echo "${YELLOW}Installing codegraph CLI + wiring opencode...${NC}"
if ! command -v codegraph >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
fi
codegraph install --target=opencode --location=global --yes

echo "${YELLOW}Linking global agent rules...${NC}"
mkdir -p ~/.claude
mkdir -p ~/.config/opencode
mkdir -p ~/.gemini
ln -sf "$(pwd)/global-agent-rules.md" ~/.claude/CLAUDE.md
ln -sf "$(pwd)/global-agent-rules.md" ~/.config/opencode/AGENTS.md
ln -sf "$(pwd)/global-agent-rules.md" ~/.gemini/AGENTS.md
ln -sf "$(pwd)/global-agent-rules.md" ~/.gemini/GEMINI.md

echo "${YELLOW}Installing skills via npx skills...${NC}"
_skills_src="$HOME/.agents/skills"
SKILLS_FILE="$(pwd)/skills/skills.yml"
SKILLS_VERSION="1.5.9"

# nuke all installed skills for clean state
echo "${YELLOW}  Removing all installed skills...${NC}"
npx "skills@${SKILLS_VERSION}" remove -g --all -y 2>/dev/null
rm -rf "$_skills_src"/*(N)

# install from config
repos=("${(@f)$(yq '.install | keys | .[]' "$SKILLS_FILE")}")
for repo in "${repos[@]}"; do
  skills_val=$(yq ".install[\"$repo\"].skills" "$SKILLS_FILE")
  agents_raw=$(yq ".install[\"$repo\"].agents | join(\",\")" "$SKILLS_FILE")

  agent_flags=()
  for a in "${(@s:,:)agents_raw}"; do
    agent_flags+=(-a "$a")
  done

  if [[ "$skills_val" == "*" ]]; then
    skill_flags=(--skill '*')
  else
    skill_names=("${(@f)$(yq ".install[\"$repo\"].skills | .[]" "$SKILLS_FILE")}")
    skill_flags=()
    for s in "${skill_names[@]}"; do
      skill_flags+=(--skill "$s")
    done
  fi

  echo "  Installing $repo..."
  npx "skills@${SKILLS_VERSION}" add -g -y "$repo" "${skill_flags[@]}" "${agent_flags[@]}"
done

echo "${YELLOW}Linking personal skills...${NC}"
personal_real="$(readlink -f "$(pwd)/skills/personal/skills/code-like-joey")"
for dir in ~/.claude/skills ~/.gemini/antigravity/skills ~/.gemini/skills ~/.config/opencode/skills; do
  mkdir -p "$dir"
  # Skip agent dirs that resolve into the personal skill itself — linking
  # through them would drop links inside the repo's own skill dir.
  dir_real="$(readlink -f "$dir")"
  [[ "$dir_real" == "$personal_real" || "$dir_real" == "$personal_real"/* ]] && continue
  ln -sf "$(pwd)/skills/personal/skills/"* "$dir"
done

rm -f ~/.config/opencode/opencode.json ~/.config/opencode/opencode.jsonc
_stow opencode

# ssh
mkdir -p ~/.ssh

# Only add Includes if not already present
if [[ "$OS" == "Darwin" ]]; then
  _stow_group macos ssh
  ssh_config_appends=$(cat "${DOTS_DIR}/macos/ssh/config.append")
else
  _stow_group omarchy ssh
  _stow_group omarchy uwsm
  # Ghostty: shared base config (root pkg) + Omarchy overrides in local.conf
  _stow_group omarchy ghostty
  _stow_group omarchy hypr
  _stow_group omarchy omarchy-shell
  _install_omarchy_plugins
  _stow_group omarchy mise
  _stow_group omarchy fcitx5
  # Hyper key (keyd): hold CapsLock = Hyper (C-A-S-M), tap = Esc.
  # Lives in /etc/keyd, so this stow needs root.
  sudo stow -d "${DOTS_DIR}/omarchy" -t / keyd
  sudo systemctl enable --now keyd
  echo "${GREEN}keyd hyper key installed (hold CapsLock = Hyper, tap = Esc)${NC}"
  ssh_config_appends=$(cat "${DOTS_DIR}/omarchy/ssh/config.append")
fi
if ! grep -q "${ssh_config_appends}" ~/.ssh/config; then
  ssh_backup_file="$HOME/.ssh/config.bak_$(date '+%Y%m%d')"
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

if [[ "$OS" == "Darwin" ]]; then
  desktoppr "$(pwd)/macos/system/wallpaper/tokyo-night.jpg"

  if [[ "$CONFIGURE_OSX" == "true" ]]; then
    _configure_osx
  fi
fi
