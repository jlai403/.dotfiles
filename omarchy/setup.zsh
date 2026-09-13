# Omarchy (Arch/Hyprland) bootstrap. Implements the four _os_* hooks called by
# main.zsh. SSH + shared-platform packages (ghostty, mise) are handled there.

_os_install_apps() {
  [[ "$DO_LINUX_APPS" == true ]] || return 0

  local pkgfile="$DOTS_DIR/omarchy/Pkgfile"
  if [[ ! -f "$pkgfile" ]]; then
    echo "${RED}Missing package list: ${pkgfile}${NC}"
    return 1
  fi
  local pkgs=(${(f)"$(grep -vE '^\s*(#|$)' "$pkgfile")"})

  if ! _have yay; then
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
  local yaml="$DOTS_DIR/omarchy/plugins.yml"
  if ! _have omarchy; then
    echo "${YELLOW}omarchy CLI not found, skipping plugins${NC}"
    return 0
  fi
  if [[ ! -f "$yaml" ]]; then
    echo "${RED}Missing plugin manifest: ${yaml}${NC}"
    return 1
  fi
  if ! _have yq; then
    echo "${YELLOW}yq not found, skipping omarchy plugins${NC}"
    return 0
  fi

  local urls=("${(@f)"$(yq -r '.plugins[].url' "$yaml")"}")
  local enables=("${(@f)"$(yq -r '.plugins[].enable // false' "$yaml")"}")

  local i url name args
  for i in {1..${#urls}}; do
    url="$urls[i]"
    name="${url:t:r}"
    if [[ -d "$HOME/.config/omarchy/plugins/$name" ]]; then
      echo "${YELLOW}omarchy plugin ${name} already installed, skipping${NC}"
      continue
    fi
    args=(add "$url")
    [[ "${enables[i]}" == "true" ]] && args+=(--enable)
    omarchy plugin "${args[@]}" --yes 2>/dev/null \
      || echo "${RED}failed to add omarchy plugin ${url}${NC}"
  done
}

_os_stow_packages() {
  # Per-OS packages, incl. overrides for the root ghostty/mise packages.
  _stow_platform ghostty mise ssh
  _stow_platform uwsm hypr omarchy-shell
  _install_omarchy_plugins
  # Cloned idle service (dismisses the screensaver on pointer motion); lives in
  # ~/.config/omarchy/plugins/, so it rides alongside the cloned plugins above.
  _stow_platform idle
  # Cloned lock service (Cmd+A select-all + auto-repeat guard on the lock screen).
  _stow_platform lock
  # Cloned workspaces bar widget (only occupied numbered workspaces + the focused
  # one; lettered workspaces show their letter only while focused).
  _stow_platform workspaces
  # iStat-style stats bar widget (CPU/RAM/disk/temp sparklines + detail popup).
  _stow_platform stats
  _stow_platform fcitx5

  # Google Drive mount: rclone remote gdrive: -> ~/Google Drive
  mkdir -p "$HOME/Google Drive"
  _stow_platform rclone

  # Remote desktop: VNC server bound to the Tailscale interface, PAM auth.
  # Pre-create the dir so stow never folds ~/.config/wayvnc into the repo.
  mkdir -p "$HOME/.config/wayvnc"
  _stow_platform wayvnc
}

_os_configure() {
  if _have mise; then
    echo "${YELLOW}Installing mise-managed tools...${NC}"
    mise install
    echo "${GREEN}Mise tools installed${NC}"
  fi

  # Tailscale: reject tailnet subnet routes so home-LAN IPs always use the local
  # router path; the subnet router (alpine-caddy) stays reachable via its 100.x IP
  if ! _have tailscale; then
    echo "${YELLOW}Tailscale: skipped (not installed)${NC}"
  elif tailscale set --accept-routes=false 2>/dev/null || sudo -n tailscale set --accept-routes=false 2>/dev/null; then
    echo "${GREEN}Tailscale: accept-routes=false${NC}"
  else
    echo "${YELLOW}Tailscale: could not apply (service inactive? run: sudo tailscale set --accept-routes=false)${NC}"
  fi

  # Remove legacy ~/.config/starship.toml (starship prefers it over the stowed path)
  if [ -f ~/.config/starship.toml ]; then
    if cmp -s ~/.config/starship.toml ~/.config/starship/starship.toml \
      || { [ -f /usr/share/omarchy/config/starship.toml ] \
        && cmp -s ~/.config/starship.toml /usr/share/omarchy/config/starship.toml; }; then
      rm -f ~/.config/starship.toml
      echo "${GREEN}Removed legacy ~/.config/starship.toml${NC}"
    else
      echo "${YELLOW}~/.config/starship.toml differs from stowed config; remove manually${NC}"
    fi
  fi

  systemctl --user daemon-reload
  if rclone listremotes 2>/dev/null | grep -q '^gdrive:$'; then
    systemctl --user enable --now rclone-gdrive.service
    echo "${GREEN}Google Drive mount enabled${NC}"
  else
    echo "${YELLOW}No rclone 'gdrive:' remote yet; run 'rclone config reconnect gdrive:' to authorize${NC}"
  fi
  if _have wayvnc; then
    systemctl --user enable --now wayvnc.service
    echo "${GREEN}wayvnc enabled (Tailscale + PAM); allow it with: sudo ufw allow in on tailscale0 to any port 5900 proto tcp${NC}"
  else
    systemctl --user enable wayvnc.service
    echo "${YELLOW}wayvnc unit enabled but the package is missing; run 'omarchy pkg add wayvnc' then 'systemctl --user start wayvnc'${NC}"
  fi

  sudo loginctl enable-linger "$USER"

  # Hyper key (keyd): hold CapsLock = Hyper (C-M-A), tap = Esc.
  # Lives in /etc/keyd, so this stow needs root.
  sudo stow -d "$DOTS_DIR/omarchy" -t / keyd
  sudo systemctl enable --now keyd
  echo "${GREEN}keyd hyper key installed (hold CapsLock = Hyper, tap = Esc)${NC}"

  # libinput palm-rejection override for the built-in Apple trackpad.
  # Lives in /etc/libinput, so this stow needs root.
  sudo stow -d "$DOTS_DIR/omarchy" -t / libinput
  echo "${GREEN}libinput trackpad quirks installed (palm rejection)${NC}"
}

_os_finalize() { : }
