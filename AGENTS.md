# AGENTS.md

## Repo Overview

GNU Stow-based dotfiles repo for macOS. Each top-level directory is a stow package or config backup. `main.zsh` is the bootstrap script.

### Key Files
- `main.zsh` — bootstrap script (stow packages, append to .zshrc, link agent rules, SSH setup)
  - `--apps` — install Homebrew packages from `Brewfile` + global bun packages
  - `--osx` — apply macOS defaults from `macos/defaults.zsh`
- `Brewfile` — Homebrew brews and casks
- `Taskfile.yml` — backup/restore tasks for Antigravity (VS Code fork) and Zen browser
- `global-agent-rules.md` — shared AI agent rules, symlinked to `~/.claude/CLAUDE.md`, `~/.config/opencode/AGENTS.md`, `~/.gemini/AGENTS.md`

### Stow Packages (managed by `main.zsh`)
| Package | Target pattern | Notes |
|---------|---------------|-------|
| `stow` | `~/.stow-global-ignore` | GNU Stow ignore rules |
| `aerospace` | `~/.aerospace.toml` | Tiling window manager |
| `borders` | `~/.config/borders/bordersrc` | Window border highlight (vendored binary copied to `~/.local/bin`) |
| `ghostty` | `~/.config/ghostty/` | Terminal emulator |
| `git` | `~/.config/git/config` | Git global config |
| `nvim` | `~/.config/nvim/` | Neovim (LazyVim) |
| `tmux` | `~/.tmux.conf` | Tmux config |
| `starship` | `~/.config/starship/` | Prompt theme |
| `television` | `~/.config/television/` | TUI fuzzy finder |
| `opencode` | `~/.config/opencode/` | OpenCode AI tool config |
| `gemini` | `~/.gemini/` | Gemini CLI config |
| `ssh` | `~/.ssh/config.d/personal.conf` | SSH config (includes prepended via `config.append`) |

### Non-stowed Configs (backup/restore via `Taskfile.yml` or manual)
- `antigravity/` — VS Code fork settings, keybindings, extensions
- `zen/` — Zen browser themes, keyboard shortcuts, containers
- `macos/` — macOS system defaults (Dock, trackpad, keyboard, login items)
- `wallpaper/` — desktop wallpaper (set via `desktoppr`)
- `raycast/` — Raycast scripts
- `stats-menu/` — Stats.app menu bar plist

### Skills Submodules
Git submodules under `skills/`, linked to gemini and opencode config dirs during setup:
- `skills/superpowers` — agent workflow skills
- `skills/excalidraw-diagram` — diagram generation
- `skills/duckdb-skills` — DuckDB query/read skills

### Private Dotfiles (`~/.dotfiles_private`)
Optional companion repo at `../.dotfiles_private` (sibling directory). If present, `main.zsh` will:
- Stow its `ssh/` package (additional SSH configs)
- Run its `main.zsh` if it exists

`zsh/sources.zsh` also conditionally sources `~/.dotfiles_private/zsh/private.zsh`.

Never commit private dotfiles content to this repo.

## Build/Test Commands
- Run setup: `./main.zsh` (base), `./main.zsh --apps` (install packages), `./main.zsh --osx` (macOS defaults)
- Verify symlinks: `ls -la ~ | grep -E '\.dotfiles'`
- Backup before testing: `cp ~/.zshrc ~/.zshrc.backup`
- Backup Antigravity: `task antigravity:backup`
- Backup Zen: `task zen:backup`

## Code Style Guidelines

### Shell Scripts (Zsh) — Modular Structure
- `zsh/exports.zsh`: Environment variables, PATH, tool initialization
- `zsh/aliases.zsh`: Command aliases and utility functions
- `zsh/sources.zsh`: Plugin sourcing (zsh-autosuggestions, syntax-highlighting)
- `zsh/hooks.zsh`: Zsh hooks (auto-ls, git auto-pull)
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
