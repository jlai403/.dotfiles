# Dotfiles Restructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorganize the GNU Stow dotfiles repo so the platform is the top-level organizing unit. The repo root stays the shared/common layer stowed on both macOS and Linux. Two platform dirs hold each machine's content: `macos/` (macOS-only apps + system configs + backups) and `omarchy/` (the Omarchy/Arch host's apps + configs).

**Architecture:** The repo root stays flat (one stow package per dir, canonical `_stow <pkg>` unchanged) for the common layer. Two platform dirs, `macos/` and `omarchy/`, mirror that flat shape. `main.zsh` stows root packages always, then `_stow_group macos <pkg>` (on Darwin) or `_stow_group omarchy <pkg>` (on Linux). Platform is visible structurally (folders, not scattered `if` logic), fixing the current scattering of `macos/`-related content across top-level `macos/`, root packages, and `backups/`.

**Tech Stack:** GNU Stow, Zsh (`main.zsh` bootstrap), Task (go-task) for backups, shell.

**Spec:** N/A — ad-hoc reorganization agreed in conversation. Design decisions locked with the user:
1. OS/platform is the top-level unit; repo root is the common layer stowed on both.
2. No `configs/` sub-level under platform dirs — use `stow -d <osdir> <pkg>` per package.
3. `borders` is macOS-only; `raycast/` + `stats-menu/` move under `macos/backups/` as manual-only backups (no Taskfile entries).
4. The `stow/` package (holding `.stow-global-ignore`) is **dropped entirely**. Global stow ignores move to a repo-root `.stowrc` (the documented Stow mechanism for per-directory default options), which `main.zsh` picks up automatically since it runs every stow from `$DOTS_DIR`. The `~/.stow-global-ignore` symlink is removed.
5. Linux platform dir is named `omarchy/` (host-named), holding `ssh/` + `uwsm/` as separate packages (uwsm does NOT merge into a single omarchy package — avoids confusing `_stow_group omarchy omarchy`).
6. SSH packages lose their OS suffix and are disambiguated by their platform parent: `macos/ssh/` + `omarchy/ssh/` (both still contain `.ssh/config.d/personal.conf`; only the 1Password socket path differs).

## Global Constraints

- Do not change any package's internal structure or target path — only the top-level directory a package lives under (`git mv`). Exception: the SSH packages are renamed `ssh-mac`/`ssh-linux` → `ssh` as part of the move.
- A repo-root `.stowrc` carries the global stow ignores (`.DS_Store`, `^\.stow-local-ignore$`). Every stow invocation must run with cwd = `$DOTS_DIR` so Stow reads it. The old `stow/` package + `~/.stow-global-ignore` symlink are removed.
- `zsh/` must remain at repo root so the existing `~/.zshrc` glob `~/.dotfiles/zsh/*.zsh` keeps working (zero change to `.zshrc` sourcing). This is the one root-level non-stow exception.
- No trailing whitespace in edited files.
- Platform packages:
  - `macos/` = aerospace, borders, ssh
  - `omarchy/` = ssh, uwsm
- Root/common packages (stowed on both OSes): ghostty, git, nvim, starship, tmux, herdr, television, zed, cliamp, opencode, gemini, plus `zsh/`, `skills/`, `docs/`. (The `stow/` package is removed.)

## main.zsh stow calls after change

- Root (via existing `_stow`, cwd = `$DOTS_DIR`): `cliamp`, `ghostty`, `git`, `nvim`, `herdr` (`--no-folding`), `tmux`, `zed`, `starship`, `television`, `opencode`, `gemini`
- `macos/` (via `_stow_group macos`): `aerospace`, `borders`, `ssh`
- `omarchy/` (via `_stow_group omarchy`): `ssh`, `uwsm`

No `-d` existence guards needed — all package files exist.

---

### Task 0: Migrate global stow ignores from the `stow/` package to a repo-root `.stowrc`

**Files:**
- Delete: `stow/` package (holds `stow/.stow-global-ignore`)
- Add: `.stowrc` at repo root
- Modify: `main.zsh` (remove `_stow stow` on line 146)
- Remove the `~/.stow-global-ignore` home symlink owned by the old package

**Interfaces:**
- Consumes: the existing `stow/.stow-global-ignore` rules
- Produces: repo-root `.stowrc` with equivalent `--ignore` options; `stow/` package removed

Rationale: Stow reads a `.stowrc` in the current directory for default options. `main.zsh` runs every stow from `$DOTS_DIR` (repo root), so a repo-root `.stowrc` is picked up automatically — no `stow/` package and no home symlink needed.

- [ ] **Step 1: Create the repo-root `.stowrc`**

```bash
cd /Users/jlai/.dotfiles
```

Write `.stowrc` with content (mirrors the old `.stow-global-ignore`):

```
# Global stow ignores — read from every stow invocation run in this directory.
# main.zsh always runs stow with cwd = $DOTS_DIR, so these apply to all packages.
--ignore=\.DS_Store
--ignore=^\.stow-local-ignore$
```

- [ ] **Step 2: Remove the `_stow stow` call from `main.zsh`**

Delete line 146 (`_stow stow`). The package no longer exists.

- [ ] **Step 3: Delete the `stow/` package and its home symlink**

```bash
cd /Users/jlai/.dotfiles
git rm -r stow
rm -f ~/.stow-global-ignore
```

- [ ] **Step 4: Verify `.stowrc` is honored**

```bash
cd /Users/jlai/.dotfiles
zsh -n main.zsh && echo "main.zsh OK"
mkdir -p /tmp/stowtest
stow -nv -d macos -t /tmp/stowtest aerospace 2>&1 | rg -i 'DS_Store' && echo "FAIL: .DS_Store should be ignored" || echo "OK: .stowrc global ignore active"
rm -rf /tmp/stowtest
```

Expected: no `.DS_Store` in stow output (proves `.stowrc` is read from cwd).

- [ ] **Step 5: Commit**

```bash
cd /Users/jlai/.dotfiles
git add -A
git commit -m "refactor(stow): replace stow/.stow-global-ignore package with repo-root .stowrc"
```

---



**Files:**
- Move: `aerospace/`, `borders/`, `ssh-mac/` → `macos/` (ssh-mac → `macos/ssh`)
- Modify: `main.zsh` (add `_stow_group` helper; update Darwin stow block + borders bin path)

**Interfaces:**
- Consumes: existing package dirs `aerospace/`, `borders/`, `ssh-mac/`
- Produces: `macos/aerospace/`, `macos/borders/`, `macos/ssh/`; `_stow_group` helper; updated Darwin stow block

- [ ] **Step 1: Create the macos dir and move the packages**

```bash
cd /Users/jlai/.dotfiles
mkdir -p macos
git mv aerospace macos/aerospace
git mv borders macos/borders
git mv ssh-mac macos/ssh
```

- [ ] **Step 2: Add a `_stow_group` helper to `main.zsh`**

Add immediately after the existing `_stow()` definition (currently lines 58-61):

```zsh
_stow_group() {
  local dir="$1" pkg="$2"
  stow -v -d "${DOTS_DIR}/${dir}" -t ~ "$pkg"
  echo "${GREEN}Symlink updated for ${pkg} (${dir})${NC}"
}
```

Note: `_stow()` stows root packages with `stow -v ${1}` (cwd = `$DOTS_DIR`). `_stow_group` stows a package from a platform dir: `stow -d <osdir> -t ~ <pkg>`.

- [ ] **Step 3: Update the Darwin stow block to use the group + fix borders bin path**

Replace the current block (lines 147-160):

```zsh
if [[ "$OS" == "Darwin" ]]; then
  _stow aerospace
  _stow borders
  mkdir -p ~/.local/bin
  ARCH=$(uname -m)
  if [[ "$ARCH" == "arm64" ]]; then
    BINARY_NAME="borders-arm64"
  else
    BINARY_NAME="borders-x86_64"
  fi
  cp "${DOTS_DIR}/borders/bin/${BINARY_NAME}" ~/.local/bin/borders
  chmod +x ~/.local/bin/borders
  echo "${GREEN}Installed vendored borders binary to ~/.local/bin/borders (${ARCH})${NC}"
fi
```

with:

```zsh
if [[ "$OS" == "Darwin" ]]; then
  _stow_group macos aerospace
  _stow_group macos borders
  mkdir -p ~/.local/bin
  ARCH=$(uname -m)
  if [[ "$ARCH" == "arm64" ]]; then
    BINARY_NAME="borders-arm64"
  else
    BINARY_NAME="borders-x86_64"
  fi
  cp "${DOTS_DIR}/macos/borders/bin/${BINARY_NAME}" ~/.local/bin/borders
  chmod +x ~/.local/bin/borders
  echo "${GREEN}Installed vendored borders binary to ~/.local/bin/borders (${ARCH})${NC}"
fi
```

- [ ] **Step 4: Syntax check + dry-run stow**

```bash
zsh -n main.zsh && echo "main.zsh OK"
mkdir -p /tmp/stowtest
stow -nv -d macos -t /tmp/stowtest aerospace
stow -nv -d macos -t /tmp/stowtest borders
stow -nv -d macos -t /tmp/stowtest ssh
rm -rf /tmp/stowtest
```

Expected: all three LINK lines resolve correctly (aerospace `.aerospace.toml` + `.local/bin/aerospace-launch-or-focus`, borders `.config/borders/bordersrc`, ssh `.ssh/config.d/personal.conf`), no target conflicts.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "move(macos): relocate aerospace, borders, ssh under macos/"
```

Verify the commit contains only renames + the `main.zsh` group changes.

---

### Task 2: Move Omarchy-only packages into `omarchy/` (incl. the ssh gate)

**Files:**
- Move: `ssh-linux/` → `omarchy/ssh/`, `omarchy/` → `omarchy/omarchy/` (n/a — see note), `uwsm/` → `omarchy/uwsm/`
- Modify: `main.zsh` (rewrite the ssh gate block)

**Note on structure:** `omarchy/` does NOT yet exist as a dir at the time of execution; the platform dir is created here. The placeholder scaffold `omarchy/` that exists today is a *Linux stow package*, distinct from the new platform-group dir `omarchy/`. To avoid confusion: `omarchy/` today is a near-empty stow package (holds uwsm's future home). After this task the `omarchy/` **platform dir** will contain `ssh/` and `uwsm/` packages. When the future hypr config lands, it will be added as `omarchy/hypr/` etc.

**Interfaces:**
- Consumes: `_stow_group` from Task 1
- Produces: `omarchy/ssh/`, `omarchy/uwsm/`; rewritten ssh gate

- [ ] **Step 1: Create the omarchy dir and move the packages**

```bash
cd /Users/jlai/.dotfiles
mkdir -p omarchy
git mv ssh-linux omarchy/ssh
git mv uwsm omarchy/uwsm
git rm -r omarchy/.stow-local-ignore 2>/dev/null; rmdir omarchy 2>/dev/null; mkdir -p omarchy
```

**Order matters:** `git mv uwsm omarchy/uwsm` requires `omarchy/` to exist and be empty-ish. The pre-existing `omarchy/` package (just `.stow-local-ignore`) becomes the platform dir root. After moving `ssh-linux` and `uwsm` into it, remove the stale `.stow-local-ignore` (no longer appropriate since `omarchy/` is now a container, not a package) and commit the container.

- [ ] **Step 2: Rewrite the ssh gate block in `main.zsh`**

Replace the current block (lines 254-264):

```zsh
if [[ "$OS" == "Darwin" ]]; then
  _stow ssh-mac
else
  _stow ssh-linux
  if [[ -d "$(pwd)/omarchy" ]]; then
    _stow omarchy
  fi
  if [[ -d "$(pwd)/uwsm" ]]; then
    _stow uwsm
  fi
fi
```

with:

```zsh
if [[ "$OS" == "Darwin" ]]; then
  _stow_group macos ssh
else
  _stow_group omarchy ssh
  _stow_group omarchy uwsm
fi
```

This single replacement handles BOTH the `macos/ssh` Darwin case AND the `omarchy/{ssh,uwsm}` Linux cases — no separate Task-1 step touches the ssh gate, so there is no stale-oldString hazard.

- [ ] **Step 3: Syntax check + dry-run stow**

```bash
zsh -n main.zsh && echo "main.zsh OK"
mkdir -p /tmp/stowtest
stow -nv -d omarchy -t /tmp/stowtest ssh
stow -nv -d omarchy -t /tmp/stowtest uwsm
rm -rf /tmp/stowtest
```

Expected: ssh links `.ssh/config.d/personal.conf`; uwsm links `.config/uwsm/env.d/dotfiles`, no errors.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "move(omarchy): relocate ssh, uwsm under omarchy/ platform dir"
```

---

### Task 3: Reorganize macOS system configs under `macos/system/`

**Files:**
- Move: `macos/defaults.zsh` → `macos/system/defaults.zsh`; `wallpaper/` → `macos/system/wallpaper/`
- Modify: `main.zsh` (paths for `_configure_osx`, `desktoppr`)

**Interfaces:**
- Consumes: `macos/` dir from Task 1 (create `macos/system/`)
- Produces: `macos/system/defaults.zsh`, `macos/system/wallpaper/tokyo-night.jpg`

- [ ] **Step 1: Move the files**

```bash
cd /Users/jlai/.dotfiles
mkdir -p macos/system
git mv macos/defaults.zsh macos/system/defaults.zsh
git mv wallpaper macos/system/wallpaper
```

- [ ] **Step 2: Update `_configure_osx` and the OSX/desktoppr block in `main.zsh`**

Replace the function (lines 29-32):

```zsh
_configure_osx() {
  source "$(pwd)/macos/defaults.zsh"
  configure_macos_defaults
}
```

with:

```zsh
_configure_osx() {
  source "$(pwd)/macos/system/defaults.zsh"
  configure_macos_defaults
}
```

Replace the OSX block (lines 280-286):

```zsh
if [[ "$OS" == "Darwin" ]]; then
  desktoppr "$(pwd)/wallpaper/tokyo-night.jpg"

  if [[ "$CONFIGURE_OSX" == "true" ]]; then
    _configure_osx
  fi
fi
```

with:

```zsh
if [[ "$OS" == "Darwin" ]]; then
  desktoppr "$(pwd)/macos/system/wallpaper/tokyo-night.jpg"

  if [[ "$CONFIGURE_OSX" == "true" ]]; then
    _configure_osx
  fi
fi
```

- [ ] **Step 3: Verify no stale path references**

```bash
cd /Users/jlai/.dotfiles
rg -n 'wallpaper|macos/defaults|macos/system/' main.zsh
```

Expected: only the two updated paths appear (`macos/system/defaults.zsh`, `macos/system/wallpaper/tokyo-night.jpg`).

- [ ] **Step 4: Syntax check + commit**

```bash
zsh -n main.zsh && echo "main.zsh OK"
git add -A
git commit -m "move(macos): group system configs under macos/system/ (defaults, wallpaper)"
```

---

### Task 4: Move macOS backup dirs under `macos/backups/`

**Files:**
- Move: `antigravity/`, `zen/`, `raycast/`, `stats-menu/`, `doll/` → `macos/backups/`
- Modify: `Taskfile.yml` (path references)

**Interfaces:**
- Consumes: existing backup dirs (contents unchanged)
- Produces: `macos/backups/{antigravity,zen,raycast,stats-menu,doll}/`

- [ ] **Step 1: Move the directories**

```bash
cd /Users/jlai/.dotfiles
mkdir -p macos/backups
git mv antigravity macos/backups/antigravity
git mv zen macos/backups/zen
git mv raycast macos/backups/raycast
git mv stats-menu macos/backups/stats-menu
git mv doll macos/backups/doll
```

- [ ] **Step 2: Update `Taskfile.yml` path references**

In `Taskfile.yml`, replace every `{{.DOTS_DIR}}/{antigravity,zen,doll}` with `{{.DOTS_DIR}}/macos/backups/{antigravity,zen,doll}`:
- antigravity: `{{.DOTS_DIR}}/antigravity` → `{{.DOTS_DIR}}/macos/backups/antigravity` (lines 13, 14, 25, 27, 36, 40, 44)
- zen: `{{.DOTS_DIR}}/zen` → `{{.DOTS_DIR}}/macos/backups/zen` (lines 59, 62, 93, 97)
- doll: `{{.DOTS_DIR}}/doll` → `{{.DOTS_DIR}}/macos/backups/doll` (lines 68, 69, 75)

Use `sd '{{.DOTS_DIR}}/antigravity' '{{.DOTS_DIR}}/macos/backups/antigravity' Taskfile.yml` (and analogous for zen, doll). No new tasks — `raycast/` and `stats-menu/` remain manual backups (confirmed with user); only the path moves.

- [ ] **Step 3: Verify the Taskfile diff**

```bash
cd /Users/jlai/.dotfiles
git diff Taskfile.yml
```

Expected: only path-string changes; no task additions/removals.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "move(backups): relocate macOS backups under macos/backups/"
```

---

### Task 5: Update `AGENTS.md` for the new structure

**Files:**
- Modify: `AGENTS.md` (Repo Overview, Stow Packages table, Platform gating, Non-stowed Configs, Build/Test commands)

**Interfaces:**
- Consumes: the final tree from Tasks 1-4

- [ ] **Step 1: Rewrite "Repo Overview"** to state the platform-first principle (root = common, `macos/` + `omarchy/` are platform dirs).

- [ ] **Step 2: Restructure the "Stow Packages" table** into three groups with a column noting their location:
  - Root/common: `ghostty`, `git`, `nvim`, `starship`, `tmux`, `herdr`, `television`, `zed`, `cliamp`, `opencode`, `gemini`
  - `macos/`: `aerospace`, `borders`, `ssh`
  - `omarchy/`: `ssh`, `uwsm`
  Keep the existing per-package target-pattern and Notes columns. Document that global ignores now live in the repo-root `.stowrc` (the `stow/` package no longer exists).

- [ ] **Step 3: Update "Platform gating"** to reference the `_stow_group` helper and the `stow -d macos|omarchy` mechanism. Note the Omarchy `ssh` vs macOS `ssh` differ only by 1Password socket path.

- [ ] **Step 4: Update "Non-stowed Configs"** section — move `macos/` and `wallpaper/` mentions to `macos/system/`, and the backup dirs to `macos/backups/`.

- [ ] **Step 5: Update "Build/Test Commands"** — add a note that `stow` dry-runs use `-d macos|omarchy` (paths unchanged for `./main.zsh`).

- [ ] **Step 6: Commit**

```bash
git add AGENTS.md
git commit -m "docs: document platform-first dotfiles structure in AGENTS.md"
```

---

### Task 6: Verify end-to-end on the real machine

**Files:**
- None (verification only)

**Interfaces:**
- Consumes: all prior tasks

- [ ] **Step 1: Full dry-run inventory**

```bash
cd /Users/jlai/.dotfiles
mkdir -p /tmp/full
# root packages
for p in cliamp ghostty git nvim herdr tmux zed starship television opencode gemini; do
  stow -nv -t /tmp/full "$p" || echo "MOVE FAILED: $p"
done
# on this Darwin machine:
for p in aerospace borders ssh; do stow -nv -d macos -t /tmp/full "$p" || echo "MOVE FAILED: $p"; done
rm -rf /tmp/full
```

Expected: all LINK lines correct, no Target/BLANK conflicts.

- [ ] **Step 2: Run real bootstrap** (backup `.zshrc` first per repo convention)

```bash
cd /Users/jlai/.dotfiles
cp ~/.zshrc ~/.zshrc.backup
./main.zsh
```

Confirm: exit 0, all `<GREEN>Symlink updated...` messages, no "already exists and is not a symlink" errors.

- [ ] **Step 3: Confirm critical symlinks + no stale stow link**

```bash
ls -la ~/.stow-global-ignore 2>/dev/null && echo "STALE LINK STILL EXISTS" || echo "OK: ~/.stow-global-ignore removed"
ls -la ~/.aerospace.toml ~/.config/borders/bordersrc ~/.ssh/config.d/personal.conf ~/.config/cliamp/config.toml 2>/dev/null
stow -nv -d macos -t /tmp/stowtest aerospace 2>&1 | rg '\.DS_Store' || echo "OK: .stowrc ignore active (.DS_Store filtered)"
```

Expected: `~/.stow-global-ignore` is gone; the four real symlinks resolve into the repo at correct (new) paths; `.DS_Store` does not appear in a `stow -n` listing (proves `.stowrc` is read from `$DOTS_DIR`).

- [ ] **Step 4: Confirm zsh boot unaffected**

```bash
/usr/bin/time -p sh -c 'for i in $(seq 1 5); do zsh -i -c true >/dev/null 2>&1; done' 2>&1 | grep real
```

Expected: ≈ same as before (no regression from relocating package dirs; `zsh/` untouched).

- [ ] **Step 5: No trailing whitespace / syntax sweep**

```bash
zsh -n main.zsh && rg -n '[[:blank:]]$' main.zsh || echo "clean"
```

- [ ] **Step 6: Final commit**

```bash
cd /Users/jlai/.dotfiles
git add -A
git commit -m "chore: verify platform-first dotfiles restructure end-to-end" || echo "nothing to commit"
```

---

## Out of scope

- `omarchy/system/` and `omarchy/backups/` slots plus `omarchy/hypr/`, `omarchy/foot/`, cliamp Hyprland bindings — deferred separate session
- Taskfile `raycast:backup/restore` + `stats-menu` tasks — manual-only backups (user-confirmed)
- The pre-existing `main.zsh` bug at line 239 (`ssh/config.append` path no longer matches after renames — should reference the SSH package's `config.append`). Not part of this restructure; flagging for awareness.

## Rollback

If `./main.zsh` fails during verification, the packages move back with:

```bash
cd /Users/jlai/.dotfiles
git revert <the move commit>
./main.zsh
```

Because each Task is an isolated commit with pure `git mv`s + path edits, reverting any single commit restores that group's previous layout.
