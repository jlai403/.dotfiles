# Dotfiles

GNU Stow-based dotfiles for macOS. Configurations for Zsh, Neovim, Ghostty, AeroSpace, tmux, and more.

## Prerequisites

- [Homebrew](https://brew.sh/)
- [GNU Stow](https://www.gnu.org/software/stow/) (`brew install stow`)

## Installation

```bash
git clone https://github.com/jlai403/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./main.zsh
```

### Flags

| Flag | Description |
|------|-------------|
| (none) | Stow all packages, update `.zshrc`, set wallpaper |
| `--apps` | Install Homebrew packages from `Brewfile` + global bun packages |
| `--osx` | Apply macOS defaults (Dock, trackpad, keyboard, login items) |

### Backup/Restore

Uses [Task](https://taskfile.dev) for non-stowed app configs:

```bash
task antigravity:backup   # Back up Antigravity (VS Code fork) settings
task antigravity:restore  # Restore Antigravity settings
task zen:backup           # Back up Zen browser config
task zen:restore          # Restore Zen browser config
```

## Structure

### Stow Packages

Symlinked to home/config directories via GNU Stow:

| Package | What it configures |
|---------|--------------------|
| `aerospace` | Tiling window manager |
| `borders` | Window border highlight |
| `gemini` | Gemini CLI |
| `ghostty` | Terminal emulator |
| `git` | Git global config |
| `nvim` | Neovim (LazyVim) |
| `opencode` | OpenCode AI tool |
| `ssh` | SSH config |
| `starship` | Prompt theme |
| `stow` | GNU Stow ignore rules |
| `television` | TUI fuzzy finder |
| `tmux` | Tmux |

### Shell (Zsh)

Modular configs sourced from `~/.zshrc`:

- `zsh/exports.zsh` — environment variables, PATH, tool init (pyenv, NVM lazy-load)
- `zsh/aliases.zsh` — aliases and utility functions
- `zsh/sources.zsh` — plugin sourcing (autosuggestions, syntax-highlighting)
- `zsh/hooks.zsh` — hooks (auto-ls on cd, git auto-pull on checkout main)

### Non-stowed Configs

Backed up manually or via `Taskfile.yml`:

- `antigravity/` — VS Code fork settings, keybindings, extensions
- `zen/` — Zen browser themes, shortcuts, containers
- `macos/` — macOS system defaults
- `wallpaper/` — desktop wallpaper
- `raycast/` — Raycast scripts
- `stats-menu/` — Stats.app menu bar config

### Other

- `Brewfile` — Homebrew brews and casks
- `global-agent-rules.md` — shared AI agent rules (symlinked to Claude, OpenCode, Gemini configs)
- `skills/` — git submodules for AI agent workflow skills

## Private Dotfiles

Optional companion repo at `~/.dotfiles_private`. If present, `main.zsh` will stow its `ssh/` package and run its `main.zsh`. Shell configs also source `~/.dotfiles_private/zsh/private.zsh` if it exists.
