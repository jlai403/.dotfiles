# macOS bootstrap. Implements the four _os_* hooks called by main.zsh.

_os_install_apps() {
  [[ "$DO_APPS" == true ]] || return 0

  echo "${BGREEN}Installing Brew apps...${NC}"
  brew bundle install
  bun add -g btca
  brew install pipx
  pipx upgrade-all 2>/dev/null
}

_os_stow_packages() {
  _stow_platform aerospace borders ghostty mise ssh zed

  # Vendored borders binary (no dotfiles-package copy step).
  mkdir -p ~/.local/bin
  local arch="$(uname -m)"
  local binary="borders-x86_64"
  [[ "$arch" == "arm64" ]] && binary="borders-arm64"
  cp "$DOTS_DIR/macos/borders/bin/$binary" ~/.local/bin/borders
  chmod +x ~/.local/bin/borders
  echo "${GREEN}Installed vendored borders binary to ~/.local/bin/borders (${arch})${NC}"
}

_os_configure() { : }

_os_finalize() {
  desktoppr "$DOTS_DIR/macos/system/wallpaper/tokyo-night.jpg"

  if [[ "$DO_OSX" == true ]]; then
    source "$DOTS_DIR/macos/system/defaults.zsh"
    configure_macos_defaults
  fi
}
