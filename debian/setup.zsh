# Debian (headless dev LXC) bootstrap. Implements the four _os_* hooks called by
# main.zsh. The toolchain is mise; there is no Homebrew, yay, or desktop app set.

_os_install_apps() {
  [[ "$DO_APPS" == true ]] || return 0

  apt-get update
  apt-get install -y zsh-autosuggestions zsh-syntax-highlighting
}

_os_stow_packages() {
  # Real dir keeps stow from folding ~/.config/mise into the repo: mise writes
  # its own state there.
  mkdir -p ~/.config/mise
  _stow_platform mise
}

# Runs after _os_stow_packages (so ~/.config/mise/config.toml exists) and before
# _setup_agents, which shells out to npx for the skills installer.
_os_configure() {
  _have mise || { echo "${RED}mise not installed; bootstrap installs it first${NC}"; return 1; }

  mise install node
  mise install || echo "${YELLOW}WARN: some mise tools failed to install (see above)${NC}"
  mise reshim

  local f
  for f in ~/.bashrc ~/.profile; do
    grep -qF 'mise activate bash' "$f" 2>/dev/null && continue
    printf '\n# mise (~/.local/bin holds the mise binary itself)\nexport PATH="$HOME/.local/bin:$PATH"\neval "$(mise activate bash)"\n' >> "$f"
  done
  grep -qF 'mise activate zsh' ~/.zshrc 2>/dev/null || \
    printf '\n# mise (~/.local/bin holds the mise binary itself)\nexport PATH="$HOME/.local/bin:$PATH"\neval "$(mise activate zsh)"\n' >> ~/.zshrc
}

_os_finalize() { : }
