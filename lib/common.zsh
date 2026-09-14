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

# Sets DO_APPS / DO_OSX. Each OS setup file self-gates on the flag it owns, so
# the pipeline calls every _os_* unconditionally.
_parse_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --osx)        DO_OSX=true ;;
      --apps)       DO_APPS=true ;;
    esac
    shift
  done
}
