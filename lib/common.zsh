# Shared constants + tiny helpers for the bootstrap.
# Sourced by main.zsh before any phase. Safe to source repeatedly.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BRED='\033[1;31m'
BGREEN='\033[1;32m'
BYELLOW='\033[1;33m'
BBLUE='\033[1;34m'
NC='\033[0m' # No Color

_have() {
  command -v "$1" >/dev/null 2>&1
}

# OS_DIR selector. `--profile` overrides; otherwise detect from the kernel and
# /etc/os-release. DOTFILES_OS_RELEASE makes the lookup testable off-platform.
_detect_os_dir() {
  [[ "$(uname -s)" == Darwin ]] && { print -n macos; return; }
  local id
  id="$(. "${DOTFILES_OS_RELEASE:-/etc/os-release}" 2>/dev/null; print -n "${ID:-}")"
  case "$id" in
    arch|omarchy)  print -n omarchy ;;
    debian|ubuntu) print -n debian ;;
    *)             print -n "" ;;
  esac
}

# Sets DO_APPS / DO_OSX / DO_SKILLS / PROFILE. Each OS setup file self-gates on
# the flag it owns, so the pipeline calls every _os_* unconditionally. DO_SKILLS
# is handled in main.zsh (runs _install_skills only, then exits).
_parse_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --osx)        DO_OSX=true ;;
      --apps)       DO_APPS=true ;;
      --skills)     DO_SKILLS=true ;;
      --profile)    PROFILE="$2"; shift ;;
    esac
    shift
  done
}
