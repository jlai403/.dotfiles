#!/usr/bin/env zsh

# Bootstrap entry point. OS-agnostic: the only platform branch is selecting
# $OS_DIR below. Platform behavior lives in macos/ | omarchy/ | debian/ setup.zsh,
# shared helpers in lib/, shared config in the repo root. See README "Architecture".

DOTS_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTS_DIR" || exit 1            # stow reads .stowrc from the cwd
PRIVATE_DOTS_DIR="$DOTS_DIR/../.dotfiles_private"

source "$DOTS_DIR/lib/common.zsh"
_parse_flags "$@"

OS_DIR="${PROFILE:-$(_detect_os_dir)}"
if [[ -z "$OS_DIR" || ! -f "$DOTS_DIR/$OS_DIR/setup.zsh" ]]; then
  echo "unsupported platform '${OS_DIR}': no $DOTS_DIR/${OS_DIR}/setup.zsh" >&2
  echo "pass --profile macos|omarchy|debian" >&2
  exit 1
fi

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

source "$DOTS_DIR/lib/stow.zsh"
source "$DOTS_DIR/lib/shared.zsh"
source "$DOTS_DIR/$OS_DIR/setup.zsh"

if [[ "$DO_SKILLS" == true ]]; then
  _install_skills
  exit 0
fi

#################################
# pipeline — each _os_* self-gates on its flag; order is significant
#################################
_os_install_apps
_stow_portable
_os_stow_packages
_os_configure
_setup_agents
_link_zshrc
_setup_ssh
_setup_private
_os_finalize
