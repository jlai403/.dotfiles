# Omarchy (Arch/Hyprland) bootstrap. Implements the four _os_* hooks called by
# main.zsh. SSH + shared-platform packages (ghostty, mise) are handled there.

_os_install_apps() {
  [[ "$DO_APPS" == true ]] || return 0

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
  local ids=("${(@f)"$(yq -r '.plugins[].id // ""' "$yaml")"}")
  local enables=("${(@f)"$(yq -r '.plugins[].enable // false' "$yaml")"}")

  local i url name args
  for i in {1..${#urls}}; do
    url="$urls[i]"
    # omarchy installs plugins under their manifest id, not the URL basename.
    name="${ids[i]:-${url:t:r}}"
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

# Make zsh the login shell, and give ~/.zshrc the omarchy-zsh base (zoptions +
# shell/all) it expects. `omarchy-setup-zsh` writes ~/.zshrc from a template but
# also clobbers ~/.inputrc and ~/.bashrc, so we prepend the base ourselves.
_ensure_login_shell() {
  local target=/usr/bin/zsh
  if [[ ! -x "$target" ]]; then
    echo "${YELLOW}zsh not installed; skipping login-shell change${NC}"
    return 0
  fi
  local current="$(getent passwd "$USER" | cut -d: -f7)"
  if [[ "$current" == "$target" ]]; then
    echo "${YELLOW}Login shell already zsh${NC}"
    return 0
  fi
  echo "${BGREEN}Setting login shell to zsh (effective next login)...${NC}"
  sudo chsh -s "$target" "$USER" \
    || echo "${YELLOW}Failed; run manually:  chsh -s $target${NC}"
}

_ensure_omarchy_zshrc() {
  if [[ ! -f /usr/share/omarchy-zsh/shell/zoptions ]]; then
    echo "${YELLOW}omarchy-zsh not installed; skipping ~/.zshrc base${NC}"
    return 0
  fi
  local zshrc="$HOME/.zshrc"
  local marker="# omarchy-zsh base (managed by dotfiles)"
  if [[ -f "$zshrc" ]] && grep -qF "$marker" "$zshrc"; then
    echo "${YELLOW}omarchy-zsh base already in ~/.zshrc${NC}"
    return 0
  fi
  local tmp="$(mktemp)"
  {
    echo "$marker"
    echo '[[ $- != *i* ]] && return'
    echo '[[ -f /usr/share/omarchy-zsh/shell/zoptions ]] && source /usr/share/omarchy-zsh/shell/zoptions'
    echo '[[ -f /usr/share/omarchy-zsh/shell/all ]] && source /usr/share/omarchy-zsh/shell/all'
    echo ''
    [[ -f "$zshrc" ]] && cat "$zshrc"
  } > "$tmp"
  mv "$tmp" "$zshrc"
  echo "${GREEN}Prepended omarchy-zsh base to ~/.zshrc${NC}"
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

  _ensure_login_shell
  _ensure_omarchy_zshrc

  # Touch Bar: the plugin reads the digitizer and holds the backlight, both
  # group `input`; tiny-dfr renders the panel. Its installer adds neither.
  if _have tiny-dfr && ! id -nG "$USER" | grep -qw input; then
    echo "${YELLOW}Adding $USER to the 'input' group (log out/in to take effect)...${NC}"
    sudo usermod -aG input "$USER"
  fi
  _have tiny-dfr && sudo systemctl enable tiny-dfr

  # Hyper key (keyd): hold CapsLock = Hyper (C-M-A), tap = Esc.
  # Lives in /etc/keyd, so this stow needs root.
  sudo stow -d "$DOTS_DIR/omarchy" -t / keyd
  sudo systemctl enable --now keyd
  echo "${GREEN}keyd hyper key installed (hold CapsLock = Hyper, tap = Esc)${NC}"

  # libinput palm-rejection override for the built-in Apple trackpad.
  # Copied, not stowed: sandboxed services (tiny-dfr, ProtectHome=true) can't
  # follow a symlink pointing into ~/.dotfiles.
  sudo install -Dm644 \
    "$DOTS_DIR/omarchy/libinput/etc/libinput/local-overrides.quirks" \
    /etc/libinput/local-overrides.quirks
  echo "${GREEN}libinput trackpad quirks installed (palm rejection)${NC}"

  # T2 MacBooks: force s2idle. The platform's deep (S3) resume is broken for long
  # sleeps (keyboard/trackpad removed, watchdog storm, tiny-dfr crash). Gate on the
  # T2 PCI IDs so non-T2 Linux and the Mac are unaffected.
  if lspci -nn 2>/dev/null | grep -qE '106b:180[12]'; then
    sudo mkdir -p /etc/systemd/sleep.conf.d          # prevent stow folding the dir
    sudo stow -d "$DOTS_DIR/omarchy" -t / t2-suspend
    sudo systemctl daemon-reload
    echo "${GREEN}T2 suspend: s2idle (freeze) configured${NC}"

    # Hybrid graphics: route the internal panel to the Intel iGPU via apple-gmux
    # (kills the amdgpu/i915 boot race and the wake-up ghost eDP-2 output). The
    # option is baked into the UKI, so rebuild only when the config changed; a
    # gitignored md5 stamp tracks it (cmp can't: /etc is a symlink to this file).
    local gmux_conf="$DOTS_DIR/omarchy/gmux/etc/modprobe.d/apple-gmux.conf"
    local gmux_stamp="$DOTS_DIR/.stow-state/markers/gmux-uki"
    local gmux_md5="$(md5sum "$gmux_conf" | cut -d' ' -f1)"
    if [[ -f "$gmux_stamp" ]] && [[ "$(<"$gmux_stamp")" == "$gmux_md5" ]]; then
      echo "${YELLOW}T2 hybrid GPU: apple-gmux already configured${NC}"
    else
      sudo mkdir -p /etc/modprobe.d
      sudo stow -d "$DOTS_DIR/omarchy" -t / gmux
      sudo mkinitcpio -P
      mkdir -p "$DOTS_DIR/.stow-state"
      print "$gmux_md5" > "$gmux_stamp"
      echo "${GREEN}T2 hybrid GPU: internal panel on Intel iGPU (apple_gmux force_igd=y)${NC}"
    fi
  else
    echo "${YELLOW}T2 suspend: not a T2 Mac, skipping${NC}"
  fi
}

_os_finalize() { : }
