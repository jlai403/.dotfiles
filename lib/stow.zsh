# Stow helpers. Every call passes an explicit -d so the cwd never matters;
# stow still reads .stowrc because main.zsh cd's into $DOTS_DIR first.

# First-stow state (markers + backups) lives in the repo, gitignored, so a fresh
# clone on a new machine reconciles again. Per-machine because it isn't committed.
STOW_STATE="$DOTS_DIR/.stow-state"
STOW_MARKERS="$STOW_STATE/markers"

# stow --adopt imports real-file conflicts into the package but refuses foreign
# symlinks (e.g. omarchy's nvim theme link), so clear those first: mv snapshots
# and removes in one step, then adopt handles the rest.
_clear_foreign_symlinks() {
  local src="$1" ts="$2" file rel target dest
  while IFS= read -r -d '' file; do
    rel="${file#$src/}"
    case "$rel" in
      .stow-local-ignore|*/.stow-local-ignore) continue ;;
    esac
    target="$HOME/$rel"
    [[ -L "$target" ]] || continue
    [[ "$(readlink -f "$target")" == "$DOTS_DIR"/* ]] && continue
    dest="$STOW_STATE/backups/$ts/$rel"
    mkdir -p "${dest:h}"
    mv "$target" "$dest"
    (( RECONCILED++ ))
  done < <(find "$src" \( -type f -o -type l \) -print0)
}

# ad-hoc adopt imported conflicting targets into the package; copy those files
# (git's change list) into the snapshot dir before git restore discards them.
_snapshot_adopted() {
  local git_path="$1" ts="$2" line relpath dest
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    [[ "${line[1,2]}" == "??" ]] && continue
    relpath="${line[4,-1]}"
    relpath="${relpath%% -> *}"
    [[ -e "$DOTS_DIR/$relpath" || -L "$DOTS_DIR/$relpath" ]] || continue
    dest="$STOW_STATE/backups/$ts/$relpath"
    mkdir -p "${dest:h}"
    cp -a "$DOTS_DIR/$relpath" "$dest"
    (( RECONCILED++ ))
  done < <(git -C "$DOTS_DIR" status --porcelain -- "$git_path")
}

# Reconcile a package on its first stow on this machine: a fresh OS install seeds
# stock configs at the targets, and stow never overwrites a real file. Clear
# foreign symlinks, stow --adopt to import real-file conflicts, snapshot the
# replaced originals, then git restore so the package content wins (the symlinks
# resolve to the repo). Markers make this one-time per package.
_stow_pkg() {
  local root="$1" git_path="$2" pkg="$3"
  local marker="$STOW_MARKERS/$OS_DIR/$pkg"

  if [[ ! -e "$marker" ]]; then
    # Block on tracked edits (adopt would clobber them); untracked files are not
    # affected by adopt/restore and shouldn't stall a fresh-install reconcile.
    if [[ -n "$(git -C "$DOTS_DIR" status --porcelain -- "$git_path" | grep -v '^??')" ]]; then
      echo "${YELLOW}$pkg: repo has local changes; skipping auto-reconcile${NC}"
    else
      local ts="$(date +%Y%m%d-%H%M%S)" RECONCILED=0
      _clear_foreign_symlinks "$root/$pkg" "$ts"
      stow --adopt -d "$root" -t ~ "$pkg" \
        || echo "${RED}$pkg: adopt failed; resolve conflicts manually${NC}"
      _snapshot_adopted "$git_path" "$ts"
      git -C "$DOTS_DIR" restore -- "$git_path" \
        || echo "${YELLOW}$pkg: git restore failed; reconcile manually${NC}"
      if [[ -n "$(git -C "$DOTS_DIR" status --porcelain -- "$git_path" | grep -v '^??')" ]]; then
        echo "${RED}$pkg: still dirty after restore; reconcile manually${NC}"
      fi
      [[ "$RECONCILED" -gt 0 ]] && echo "${YELLOW}reconciled $pkg; originals -> $STOW_STATE/backups/$ts${NC}"
      mkdir -p "${marker:h}"
      : > "$marker"
    fi
  fi

  stow -v -d "$root" -t ~ "$pkg"
}

# Root packages (shared across both OSes) -> ~
_stow() {
  local pkg
  for pkg in "$@"; do
    _stow_pkg "$DOTS_DIR" "$pkg" "$pkg"
  done
  echo "${GREEN}Symlink updated: $*${NC}"
}

# Platform package -> ~, from the current OS dir ($OS_DIR = macos | omarchy)
_stow_platform() {
  local pkg
  for pkg in "$@"; do
    _stow_pkg "$DOTS_DIR/$OS_DIR" "$OS_DIR/$pkg" "$pkg"
  done
  echo "${GREEN}Symlink updated: $* ($OS_DIR)${NC}"
}