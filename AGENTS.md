# AGENTS.md

## Repo Overview

GNU Stow-based dotfiles repo for macOS (silicon Mac) and will soon support [Omarchy](https://omarchy.org/) (Arch Linux) on an Intel Mac. Each top-level directory is a stow package or config backup. `main.zsh` is the bootstrap script, branching on `OS="$(uname -s)"` for platform-specific steps.

### Key Files
- `main.zsh` — bootstrap script (stow packages, append to .zshrc, link agent rules, SSH setup)
  - `--apps` — install Homebrew packages from `Brewfile` + global bun packages
  - `--osx` — apply macOS defaults from `macos/defaults.zsh`
- `Brewfile` — Homebrew brews and casks
- `Taskfile.yml` — backup/restore tasks for Antigravity (VS Code fork), Zen browser, and skill updates (`task skills:update` runs `npx skills update -g`)
- `global-agent-rules.md` — shared AI agent rules, symlinked to `~/.claude/CLAUDE.md`, `~/.config/opencode/AGENTS.md`, `~/.gemini/AGENTS.md`; contains the marker-fenced `CODEGRAPH_START`/`CODEGRAPH_END` block written by `codegraph install`

### Stow Packages (managed by `main.zsh`)
| Package | Target pattern | Notes |
|---------|---------------|-------|
| `stow` | `~/.stow-global-ignore` | GNU Stow ignore rules |
| `aerospace` | `~/.aerospace.toml`, `~/.local/bin/aerospace-launch-or-focus` | Tiling window manager; launch-or-focus helper for TUI bindings (stowed from `aerospace/.local/bin/aerospace-launch-or-focus`) |
| `borders` | `~/.config/borders/bordersrc` | Window border highlight (vendored binary copied to `~/.local/bin`) |
| `ghostty` | `~/.config/ghostty/` | Terminal emulator |
| `git` | `~/.config/git/config`, `~/.config/git/scripts/tidy` | Git global config; `tidy` alias runs `scripts/tidy` |
| `nvim` | `~/.config/nvim/` | Neovim (LazyVim) |
| `herdr` | `~/.config/herdr/config.toml` | Terminal multiplexer (stowed with `--no-folding`) |
| `tmux` | `~/.tmux.conf` | Tmux config |
| `zed` | `~/.config/zed/` | Zed editor; terminal wrapper `zed-tmux` installed to `~/.local/bin/zed-tmux` (source is stow-ignored) |
| `starship` | `~/.config/starship/` | Prompt theme |
| `television` | `~/.config/television/` | TUI fuzzy finder |
| `opencode` | `~/.config/opencode/` | OpenCode AI tool config |
| `gemini` | `~/.gemini/` | Gemini CLI config |
| `ssh-mac` | `~/.ssh/config.d/personal.conf` | SSH config, macOS 1Password socket (stowed on Darwin) |
| `ssh-linux` | `~/.ssh/config.d/personal.conf` | SSH config, Linux 1Password socket (stowed on Linux) |

### Platform gating
`main.zsh` sets `OS="$(uname -s)"`. macOS-only packages (`aerospace`, `borders` + vendored binary, `ssh-mac`, `desktoppr`, `--osx`, `--apps`/brew) are only run when `OS == Darwin`; Linux uses `ssh-linux`. The `zsh/` configs branch on `$OS` internally via `case`/`if` for platform-specific PATH, plugin, and env settings.

### Non-stowed Configs (backup/restore via `Taskfile.yml` or manual)
- `antigravity/` — VS Code fork settings, keybindings, extensions
- `zen/` — Zen browser themes, keyboard shortcuts, containers
- `macos/` — macOS system defaults (Dock, trackpad, keyboard, login items)
- `wallpaper/` — desktop wallpaper (set via `desktoppr`)
- `raycast/` — Raycast scripts
- `stats-menu/` — Stats.app menu bar plist

### Skills
Defined in `skills/skills.yml` — single source of truth for install + linking.
`main.zsh` nukes all installed skills and reinstalls from config (idempotent).
Only `skills/personal/` (code-like-joey) lives in-repo — symlinked to agent dirs.

**Zsh array note**: The `npx skills add` call in `main.zsh` uses zsh arrays (`agent_flags=()`, `skill_flags=()`) with `"${arr[@]}"` expansion — never string concatenation. Zsh does not word-split unquoted variables, so `$skill_flags $agent_flags` would pass everything as a single arg.

### CodeGraph
- CLI installed via standalone bundle (`~/.codegraph/` + `~/.local/bin/codegraph`); `main.zsh` installs it if missing and runs `codegraph install --target=opencode --location=global --yes` to wire the MCP server
- opencode MCP entry (`mcp.codegraph`) is committed in `opencode/.config/opencode/opencode.json`; `main.zsh` does `rm -f ~/.config/opencode/opencode.json` before `_stow opencode` because `codegraph install` replaces the stow symlink with a real file
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
- Run setup: `./main.zsh` (base), `./main.zsh --apps` (install packages), `./main.zsh --osx` (macOS defaults)
- Verify symlinks: `ls -la ~ | grep -E '\.dotfiles'`
- Verify skills: `npx skills list -g`
- Update skills: `npx skills update -g` or `task skills:update`
- Verify codegraph: `codegraph --version` and `codegraph install --print-config opencode`
- Backup before testing: `cp ~/.zshrc ~/.zshrc.backup`
- Backup Antigravity: `task antigravity:backup`
- Backup Zen: `task zen:backup`

## Code Style Guidelines

### Shell Scripts (Zsh) — Modular Structure
- `zsh/exports.zsh`: Environment variables, PATH, tool initialization
- `zsh/aliases.zsh`: Command aliases and utility functions
- `zsh/sources.zsh`: Plugin sourcing (zsh-autosuggestions, syntax-highlighting)
- `zsh/hooks.zsh`: Zsh hooks (auto-ls, git auto-pull)
- `zsh/op.zsh`: 1Password-backed secrets. `_op_env <VAR> <op://ref> [ttl]` reads from the macOS Keychain (silent, encrypted) and bootstraps from 1Password when absent, storing under service name `dotfiles/cache/op_env/<VAR>`; `op-env-reset <VAR>` (or `--all`) deletes cached entries to force a re-read. Explicitly sourced at the top of `exports.zsh` (alphabetical load would run it too late). Uses `command grep` to bypass the `grep='rg'` alias.
- Use snake_case for function names
- Define color constants at file top (RED, GREEN, etc.)
- Check file existence before modifications
- Use echo with color codes for user feedback
- Create backups before overwriting files
- Use lazy loading for heavy tools (NVM)
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

