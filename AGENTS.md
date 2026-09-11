# AGENTS.md

## Repo Overview

GNU Stow-based dotfiles repo for macOS (silicon Mac) and [Omarchy](https://omarchy.org/) (Arch Linux) on an Intel Mac. The platform is the top-level organizing unit: the repo **root holds the shared/common layer stowed on both OSes**, and two platform dirs, `macos/` and `omarchy/`, hold each machine's packages, system configs, and backups. `main.zsh` is the bootstrap script, branching on `OS="$(uname -s)"` and using the `_stow_group <dir> <pkg>` helper to stow packages from a platform dir via `stow -d <dir> -t ~ <pkg>`.

### Key Files
- `main.zsh` — bootstrap script (stow packages, append to .zshrc, link agent rules, SSH setup)
  - `--apps` — install Homebrew packages from `Brewfile` + global bun packages
  - `--linux-apps` — install Linux packages listed in `omarchy/Pkgfile` via yay (pacman only bootstraps `yay` itself if missing)
  - `--osx` — apply macOS defaults from `macos/system/defaults.zsh`
- `.stowrc` — global stow ignore rules (`\.DS_Store`, `^\.stow-local-ignore$`); read automatically because `main.zsh` runs every stow from `$DOTS_DIR`
- `Brewfile` — Homebrew brews and casks
- `omarchy/Pkgfile` — package list (Linux Brewfile equivalent) consumed by `main.zsh --linux-apps`; official-repo and AUR packages can be mixed (yay resolves each name, repo packages go through pacman's backend); dev toolchains stay in mise
- `omarchy/plugins.yml` — Omarchy shell plugin manifest consumed by `main.zsh`'s `_install_omarchy_plugins`; each entry is a git clone into `~/.config/omarchy/plugins/<id>/` (real checkout, not stowed), with `enable: true` passing `--enable`; skipped when the plugin dir already exists
- `Taskfile.yml` — backup/restore tasks for Antigravity (VS Code fork), Zen browser, the 1Password allowed-browsers list (`omarchy/backups/1password/custom_allowed_browsers`), the keyd hyper-key config (`keyd:restore`), and skill updates (`task skills:update` runs `npx skills update -g`)
- `global-agent-rules.md` — shared AI agent rules, symlinked to `~/.claude/CLAUDE.md`, `~/.config/opencode/AGENTS.md`, `~/.gemini/AGENTS.md`; contains the marker-fenced `CODEGRAPH_START`/`CODEGRAPH_END` block written by `codegraph install`

### Stow Packages (managed by `main.zsh`)
Packages at repo **root** are stowed on both OSes; platform packages live under `macos/` (Darwin) or `omarchy/` (Linux) and are stowed via `_stow_group <dir> <pkg>`.

**Root / common (all OSes):**
| Package | Target pattern | Notes |
|---------|---------------|-------|
| `ghostty` | `~/.config/ghostty/config` | Shared Ghostty **base** (cursor, shell-integration, CSI-u Enter binds); ends with `config-file = ~/.config/ghostty/local.conf` — platform pkgs supply `local.conf`. Includes must be `~`-absolute: ghostty resolves relative paths against the including file, and keys in a file always lose to keys from files it includes |
| `git` | `~/.config/git/config`, `~/.config/git/scripts/tidy` | Git global config; `tidy` alias runs `scripts/tidy` |
| `nvim` | `~/.config/nvim/lua/plugins/theme.lua` | Only the colorscheme is tracked; everything else is omarchy's nvim baseline (`omarchy-nvim` skel on Linux, a materialized copy on macOS) |
| `herdr` | `~/.config/herdr/config.toml` | Terminal multiplexer (stowed with `--no-folding`); shared keymap — mac `ctrl+hjkl` pane focus + alt-chord fast path (Hyprland passes ALT through to terminals) |
| `tmux` | `~/.tmux.conf` | Tmux config |
| `zed` | `~/.config/zed/settings.json`, `~/.local/bin/zed-tmux` | Zed editor; `zed-tmux` wrapper is a package file (no separate copy step) |
| `television` | `~/.config/television/` | TUI fuzzy finder (not installed on Omarchy yet — mac-only in practice) |
| `opencode` | `~/.config/opencode/` | `opencode.jsonc` + `tui.jsonc` + local plugins (`herdr-tui-session.js`, `plugins/herdr-agent-state.js`, `opencode-quota/quota-toast.jsonc`) + on-demand `opencode-bedrock.json`; `share` disabled, codegraph MCP wired |
| `cliamp` | `~/.config/cliamp/config.toml` | Spotify TUI (cross-platform; stowed on Darwin and Linux) |

**`macos/` (Darwin only):**
| Package | Target pattern | Notes |
|---------|---------------|-------|
| `aerospace` | `~/.aerospace.toml`, `~/.local/bin/aerospace-launch-or-focus` | Tiling window manager; launch-or-focus helper for TUI bindings (stowed from `macos/aerospace/.local/bin/aerospace-launch-or-focus`) |
| `borders` | `~/.config/borders/bordersrc` | Window border highlight (vendored binary copied to `~/.local/bin`) |
| `ghostty` | `~/.config/ghostty/local.conf`, `~/.config/ghostty/ghostty-tmux.sh` | macOS Ghostty overrides (TokyoNight Moon, font-size 14, `macos-option-as-alt`, cmd unbinds) on top of the shared base |
| `ssh` | `~/.ssh/config.d/personal.conf` | SSH config, macOS 1Password socket |

**`omarchy/` (Linux only):**
| Package | Target pattern | Notes |
|---------|---------------|-------|
| `ssh` | `~/.ssh/config.d/personal.conf`, `~/.ssh/config.d/githubs.conf` | SSH config, Linux 1Password socket; `githubs.conf` defines the `ghjlai`/`ghstellar` (github.com) and `forgejo` (git.ts.jlai.ca) host aliases for the agent |
| `uwsm` | `~/.config/uwsm/env.d/dotfiles` | Desktop-session env for Omarchy (sets `TERMINAL=ghostty`, 1Password `SSH_AUTH_SOCK`) |
| `ghostty` | `~/.config/ghostty/local.conf`, `~/.config/ghostty/overrides.conf` | `local.conf` includes omarchy's packaged default (read-only `/usr/share/omarchy/config/ghostty/config`) then `overrides.conf`; only the deviation (`font-size = 8`) is tracked — omarchy updates keep flowing |
| `hypr` | `~/.config/hypr/` | Hyprland **user overrides** (`bindings.lua`, `input.lua`, `monitors.lua`) + `~/.local/bin/omarchy-hyprland-window-quit-app`. `bindings.lua` is the mac-keyboard parity layer: a **catch-all Cmd shim** forwards every plain `SUPER+key` (letters minus Q/O, `code:10..19` digits, TAB + common symbols) as CTRL via `mac_shortcut` — global interception, silent in `terminal`-tagged windows, so web apps that check `e.ctrlKey` (Google Sheets) work; keys with compositor jobs are excluded from the loop (Q quit-app, O pop-out, C/V/X clipboard trio keeping omarchy's smart copy/paste/cut — Cmd+V→Shift+Insert in terminals, Ctrl equivalents in apps — RETURN terminal, SPACE menu, ESC system menu, BACKSPACE transparency, comma notifications, Home width-restore, PRINT picker) and Cmd+W is terminal-aware (closes the focused window when a terminal, otherwise forwards Ctrl+W tab-close, replacing omarchy's always-close-window) while Cmd+arrows are special-cased to HOME/END/PAGE keys; Cmd+Shift stays a curated list. New plain-SUPER compositor binds must be added to the `cmd_keys` exclusion (or keep-list), not just bound; workspace nav on ALT+digits, swap on ALT+SHIFT+hjkl; launcher re-homes live on SUPER+CTRL(+SHIFT) — releasing a chord there requires also unbinding omarchy's hidden `SUPER+CTRL` toggles (utilities.lua); window state on HYPER (CapsLock chord, `keyd` pkg). The entry point and templates (`hyprland.lua`, `looknfeel.lua`, `autostart.lua`, `hyprsunset.conf`, `xdph.conf`) are omarchy-owned real files on disk — NOT tracked; `hyprland.lua` requires `hypr.looknfeel`/`hypr.autostart`, so those two templates must exist |
| `omarchy-shell` | `~/.config/omarchy/` | Omarchy shell config (`shell.json`, `hooks/post-update.d/*.hook`, `defaults/agent`) |

**Omarchy plugins** are not stowed — declared in `omarchy/plugins.yml`, `_install_omarchy_plugins` in `main.zsh` clones each URL into `~/.config/omarchy/plugins/<id>/` on every Linux bootstrap (skipping present dirs).
| `mise` | `~/.config/mise/config.toml` | mise tool manifest (codex/gh/node/opencode); `main.zsh` runs `mise install` on Linux |
| `keyd` | `/etc/keyd/default.conf` | Hyper key: hold CapsLock = Hyper (C-A-S-M chord), tap = Esc. Stowed with `sudo stow -d omarchy -t / keyd` (only package targeting `/`); `main.zsh` enables the unit, or run `task keyd:restore`. Hyprland bindings address the chord as `SUPER + SHIFT + CONTROL + ALT + <key>` |
| `fcitx5` | `~/.config/fcitx5/config` | XCompose IME (compose sequences via fcitx5); trigger keys cleared so `ctrl+space` reaches herdr's prefix instead of toggling the IME |

### Platform gating
`main.zsh` sets `OS="$(uname -s)"`. Root packages (common) are stowed on both OSes via `_stow`. macOS-only content (`macos/aerospace`, `macos/borders` + vendored binary, `macos/ghostty`, `macos/ssh`, `macos/system/` desktoppr + `--osx`, `--apps`/brew) is only run when `OS == Darwin`; Linux uses `omarchy/ssh`, `omarchy/uwsm`, `omarchy/ghostty`, `omarchy/hypr`, `omarchy/omarchy-shell`, `omarchy/mise`, and `--linux-apps`. Both use the `_stow_group <dir> <pkg>` helper (`stow -d <dir> -t ~ <pkg>`). The `macos/ssh` and `omarchy/ssh` packages differ by the 1Password agent socket path (and `omarchy/ssh` adds the `githubs.conf` host aliases). The `zsh/` configs branch on `$OS` internally via `case`/`if` for platform-specific PATH, plugin, and env settings. `main.zsh` pre-creates `~/.config/ghostty` and `~/.config/cliamp` so stow never folds those dirs into the repo.

### Maintenance philosophy — track deviations only
Files identical to (or pure comment-templates of) upstream defaults are NOT tracked. Pristine references on Omarchy:
- `/usr/share/omarchy/config/<app>/` — user-config templates omarchy installs to `~/.config/` (e.g. `hypr/`, `ghostty/`)
- `/usr/share/omarchy/default/hypr/` — the hypr lua module library loaded via `require("default.hypr.*")`
- `/etc/skel/.config/nvim/` — omarchy-nvim's nvim baseline
Before editing a config that omarchy owns, diff against the pristine copy; only keep the delta in this repo. Watch out when comparing: `diff | head` hides diff's exit code, and stow-created symlinks make "the same file" mean "the repo file" — check `readlink` before `rm`.

### SSH host aliases (git `insteadOf` shortcuts)
`git/.config/git/config` defines `gh:`/`ghjlai:`/`ghstellar:`/`forgejo:` URL rewrites. `omarchy/ssh/.ssh/config.d/githubs.conf` provides the matching host aliases on Linux (1Password agent socket); the macOS side's aliases come from `~/.dotfiles_private/ssh/.ssh/config.privated/jlai.conf`. On Linux, `config.d/*.conf` is included before `config.privated/*.conf`, so the agent socket here overrides the macOS socket in the private config.

### Omarchy / zsh
On Omarchy (Arch Linux), zsh is the user shell (not bash). `--linux-apps` installs `omarchy-zsh` plus zsh plugins and shared tools, and prints the `chsh -s /usr/bin/zsh` step. The canonical source chain: Omarchy's shared config (`omarchy-zsh`) → our `zsh/*.zsh` modules → tool inits. `zsh/overrides.zsh` re-runs Omarchy's `tsl`/`hsl` swarm functions under `emulate -L bash` so their 0-based array indexing survives zsh's 1-based arrays; no-op on macOS. Desktop env for the Hyprland session lives in `omarchy/uwsm/.config/uwsm/env.d/dotfiles` (sourced by uwsm, not the shell rc).

### Non-stowed Configs (backup/restore via `Taskfile.yml` or manual)
- `macos/backups/antigravity/` — VS Code fork settings, keybindings, extensions
- `macos/backups/zen/` + `omarchy/backups/zen/` — Zen browser themes, keyboard shortcuts, containers (per-OS copies; `zen:backup`/`zen:restore` pick the dir via `uname`)
- `omarchy/backups/1password/` — 1Password allowed-browsers list (`custom_allowed_browsers`); restored to `/etc/1password/` via `task 1password:restore` (Zen desktop integration)
- `macos/system/` — macOS system defaults (Dock, trackpad, keyboard, login items) + `wallpaper/tokyo-night.jpg`
- `macos/backups/raycast/` — Raycast scripts
- `macos/backups/stats-menu/` — Stats.app menu bar plist

### Skills
Defined in `skills/skills.yml` — single source of truth for install + linking.
`main.zsh` nukes all installed skills and reinstalls from config (idempotent).
Only `skills/personal/` (code-like-joey) lives in-repo — symlinked to agent dirs.

**Zsh array note**: The `npx skills add` call in `main.zsh` uses zsh arrays (`agent_flags=()`, `skill_flags=()`) with `"${arr[@]}"` expansion — never string concatenation. Zsh does not word-split unquoted variables, so `$skill_flags $agent_flags` would pass everything as a single arg. Related pitfall: an **unquoted** `$(...)` nested inside `${(...)}` (e.g. `${(f)$(grep ...)}`) has its lines joined with the first IFS char *before* the flag applies, collapsing everything into one element — always quote the substitution: `${(f)"$(...)"}`. (This silently broke `--linux-apps` package parsing; `_install_linux_apps` now uses the quoted form.)

### CodeGraph
- CLI installed via standalone bundle (`~/.codegraph/` + `~/.local/bin/codegraph`); `main.zsh` installs it if missing and runs `codegraph install --target=opencode --location=global --yes` to wire the MCP server
- opencode MCP entry (`mcp.codegraph`) is committed in `opencode/.config/opencode/opencode.jsonc` (codegraph is jsonc-aware); `main.zsh` does `rm -f ~/.config/opencode/opencode.json{,c}` before `_stow opencode` because `codegraph install` replaces the stow symlink with a real file
- The `CODEGRAPH_START`/`CODEGRAPH_END` block in `global-agent-rules.md` is maintained by `codegraph install` — keep it in sync if rerunning the installer
- Index projects with `codegraph init` (creates `.codegraph/`); upgrade CLI with `codegraph upgrade`
- Only opencode is wired (not Claude/Gemini MCP)

### Private Dotfiles (`~/.dotfiles_private`)
Optional companion repo at `../.dotfiles_private` (sibling directory). If present, `main.zsh` will:
- Stow its `ssh/` package (additional SSH configs)
- Run its `main.zsh` if it exists

`zsh/sources.zsh` also conditionally sources `~/.dotfiles_private/zsh/private.zsh`.

Never commit private dotfiles content to this repo.

## Build/Test Commands
- Run setup: `./main.zsh` (base), `./main.zsh --apps` (install packages), `./main.zsh --linux-apps` (Linux packages), `./main.zsh --osx` (macOS defaults)
- Verify symlinks: `ls -la ~ | grep -E '\.dotfiles'`
- Dry-run stow (no changes): `stow -nv -t /tmp/stowtest <pkg>` for root packages, or `stow -nv -d macos -t /tmp/stowtest <pkg>` / `stow -nv -d omarchy -t /tmp/stowtest <pkg>` for platform packages
- Verify skills: `npx skills list -g`
- Update skills: `npx skills update -g` or `task skills:update`
- Verify codegraph: `codegraph --version` and `codegraph install --print-config opencode`
- Check a config against omarchy's pristine default: `diff /usr/share/omarchy/config/<app>/<file> <repo copy>` (full file, never `| head` — it swallows diff's exit code)
- Backup before testing: `cp ~/.zshrc ~/.zshrc.backup`
- Backup Antigravity: `task antigravity:backup`
- Backup Zen: `task zen:backup`

## Code Style Guidelines

### Shell Scripts (Zsh) — Modular Structure
- `zsh/exports.zsh`: Environment variables, PATH, tool initialization
- `zsh/aliases.zsh`: Command aliases and utility functions
- `zsh/sources.zsh`: Plugin sourcing (zsh-autosuggestions, syntax-highlighting)
- `zsh/hooks.zsh`: Zsh hooks (auto-ls, git auto-pull, lazy mise activation)
- `zsh/keys.zsh`: Key bindings (alt-arrow word motion, etc.)
- `zsh/overrides.zsh`: zsh-compat wrappers for Omarchy's bash-indexed `tsl`/`hsl` (via `emulate -L bash`)
- `zsh/op.zsh`: 1Password-backed secrets. `_op_env <VAR> <op://ref> [ttl]` reads from the macOS Keychain (silent, encrypted) and bootstraps from 1Password when absent, storing under service name `dotfiles/cache/op_env/<VAR>`; `op-env-reset <VAR>` (or `--all`) deletes cached entries to force a re-read. Explicitly sourced at the top of `exports.zsh` (alphabetical load would run it too late). Uses `command grep` to bypass the `grep='rg'` alias.
- Use snake_case for function names
- Define color constants at file top (RED, GREEN, etc.)
- Check file existence before modifications
- Use echo with color codes for user feedback
- Create backups before overwriting files
- Use lazy loading for heavy tools (NVM, pyenv): keep the cheap shim PATH prepend eager, defer the expensive init (`load-nvm` / `load-pyenv` + `nvm()` / `pyenv()` wrappers) to first use
- Maintain alphabetical ordering within sections

### Lua (Neovim configs)
- Use local variable declarations
- Follow LazyVim plugin specification format
- Use table.extend for config merging
- Minimal comments, only when necessary
- Maintain lazy-lock.json for plugin versions

### General
- No trailing whitespace
- Consistent indentation (2 spaces for Lua, tabs for shell)
- Test in isolated environment before committing

