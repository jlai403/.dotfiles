# Stow helpers. Every call passes an explicit -d so the cwd never matters;
# stow still reads .stowrc because main.zsh cd's into $DOTS_DIR first.

# Root packages (shared across both OSes) -> ~
_stow() {
  stow -v -d "$DOTS_DIR" -t ~ "$@"
  echo "${GREEN}Symlink updated: $*${NC}"
}

# Platform package -> ~, from the current OS dir ($OS_DIR = macos | omarchy)
_stow_platform() {
  stow -v -d "$DOTS_DIR/$OS_DIR" -t ~ "$@"
  echo "${GREEN}Symlink updated: $* ($OS_DIR)${NC}"
}
