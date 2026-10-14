# OS-agnostic bootstrap phases. Platform-specific work lives in
# macos/setup.zsh | omarchy/setup.zsh.

_stow_shared() {
  # Real dirs keep stow from folding them into the repo (a folded dir would
  # capture app-written state: herdr logs/sockets, ~/.ssh known_hosts, ...).
  mkdir -p ~/.config/ghostty ~/.config/cliamp ~/.config/herdr ~/.config/zed ~/.local/bin ~/.ssh

  _stow cliamp ghostty git herdr nvim inputrc tmux zed television starship
}

_link_zshrc() {
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
}

_setup_agents() {
  echo "${YELLOW}Installing codegraph CLI + wiring opencode...${NC}"
  if ! _have codegraph; then
    curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
  fi
  codegraph install --target=opencode --location=global --yes

  echo "${YELLOW}Linking global agent rules...${NC}"
  mkdir -p ~/.claude ~/.config/opencode ~/.gemini
  ln -sf "$DOTS_DIR/global-agent-rules.md" ~/.claude/CLAUDE.md
  ln -sf "$DOTS_DIR/global-agent-rules.md" ~/.config/opencode/AGENTS.md
  ln -sf "$DOTS_DIR/global-agent-rules.md" ~/.gemini/AGENTS.md
  ln -sf "$DOTS_DIR/global-agent-rules.md" ~/.gemini/GEMINI.md

  _install_skills

  # herdr owns its opencode integration files (agent-state plugin + tui session);
  # stowing them would freeze herdr-managed versions in the repo. Provision them
  # first so fresh machines get the current integration without tracking herdr's
  # glue, then clear the config files it rewrote so the stowed versions win.
  if _have herdr; then
    herdr integration install opencode >/dev/null
  fi
  rm -f ~/.config/opencode/opencode.json ~/.config/opencode/opencode.jsonc \
    ~/.config/opencode/tui.jsonc
  _stow opencode
}

_install_skills() {
  echo "${YELLOW}Installing skills from jlai403/skills...${NC}"
  curl -fsSL https://raw.githubusercontent.com/jlai403/skills/main/install.sh | bash
}

_setup_ssh() {
  local appends="$(cat "$DOTS_DIR/$OS_DIR/ssh/config.append")"

  # Only add Includes if not already present
  if ! grep -q "${appends}" ~/.ssh/config 2>/dev/null; then
    if [ -f ~/.ssh/config ]; then
      local backup="$HOME/.ssh/config.bak_$(date '+%Y%m%d')"
      cp ~/.ssh/config "$backup"
      echo "created backup of ~/.ssh/config -> ${backup}"
    fi

    local tmpfile="$(mktemp)"
    echo "${appends}" > "$tmpfile"
    [ -f ~/.ssh/config ] && cat ~/.ssh/config >> "$tmpfile"
    mv "$tmpfile" ~/.ssh/config
    echo "${GREEN}Added SSH Includes to ~/.ssh/config${NC}"
  else
    echo "${YELLOW}SSH Includes already present in ~/.ssh/config ${NC}"
  fi
}

_setup_private() {
  [ -d "$PRIVATE_DOTS_DIR" ] || return 0

  echo "Symlinking private dotfiles ssh"
  ( cd "$PRIVATE_DOTS_DIR" && stow -v ssh && echo "${GREEN}Symlink updated: ssh (private)${NC}" )

  if [ -f "$PRIVATE_DOTS_DIR/main.zsh" ]; then
    echo "${YELLOW}Running private dotfiles setup...${NC}"
    source "$PRIVATE_DOTS_DIR/main.zsh"
  fi
}
