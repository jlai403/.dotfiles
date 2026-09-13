# Dotfiles

GNU Stow-based dotfiles for macOS (silicon Mac) and [Omarchy](https://omarchy.org/) (Arch Linux on an Intel Mac). Configurations for Zsh, Neovim, Ghostty, Hyprland, tmux, and more. Uses two platform dirs — `macos/` and `omarchy/` — alongside a shared root layer.

## Prerequisites

- GNU Stow (`brew install stow`, or `sudo pacman -S stow` on Arch)
- [Task](https://taskfile.dev) for backup/restore (cpools — helpful but optional on Linux)

## Installation

```bash
git clone git@github.com:jlai403/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./main.zsh
```

### Flags

| Flag | Description |
|------|-------------|
| (none) | Stow all packages, update `.zshrc`, set wallpaper |
| `--apps` | Install Homebrew packages from `Brewfile` + global bun packages |
| `--linux-apps` | Install Linux packages from `omarchy/Pkgfile` via yay (bootstraps `yay` via pacman if missing) |
| `--osx` | Apply macOS defaults (Dock, trackpad, keyboard, login items) |

On Omarchy, `./main.zsh` additionally runs `mise install` to install the tools declared in `omarchy/mise/.config/mise/config.toml` (codex, gh, node, opencode).

### Backup/Restore

Uses [Task](https://taskfile.dev) for non-stowed app configs:

```bash
task antigravity:backup   # Back up Antigravity (VS Code fork) settings
task antigravity:restore  # Restore Antigravity settings
task zen:backup           # Back up Zen browser config
task zen:restore          # Restore Zen browser config
task 1password:backup     # Back up the 1Password allowed-browsers list
task 1password:restore    # Restore it to /etc (needed for 1Password desktop integration)
```

### 1Password + Zen browser

On Omarchy, the 1Password desktop app won't accept the Zen browser unless `zen-bin` is in its allowed list. `task 1password:restore` installs `omarchy/backups/1password/custom_allowed_browsers` to `/etc/1password/custom_allowed_browsers`.

After that: the 1Password extension is installed and active in Zen but **not pinned to the toolbar** (a manual browser step — pin it via the puzzle-piece menu in the toolbar or via `about:addons` → 1Password → Pin to Toolbar). The pin state lives in Zen's `prefs.js`, which is gitignored.

## Structure

### Stow Packages

Symlinked to home/config directories via GNU Stow. Root packages stow on both OSes; `macos/` and `omarchy/` packages are platform-gated.

| Package | What it configures | Platform |
|---------|--------------------|----------|
| `aerospace` | Tiling window manager | macOS |
| `borders` | Window border highlight | macOS |
| `cliamp` | Spotify TUI | both |
| `ghostty` | Terminal emulator — shared base config + per-OS `local.conf` | both |
| `git` | Git global config | both |
| `herdr` | Terminal multiplexer | both |
| `inputrc` | Readline keybindings | both |
| `nvim` | Neovim colorscheme (baseline comes from omarchy-nvim) | both |
| `opencode` | OpenCode AI tool | both |
| `ssh` | SSH config (1Password agent socket; Omarchy also adds `ghjlai`/`ghstellar`/`forgejo` host aliases) | per-OS |
| `television` | TUI fuzzy finder | both |
| `tmux` | Tmux | both |
| `zed` | Zed editor | both |
| `ghostty` | Ghostty `local.conf` overrides (macOS keybinds/font, Omarchy include + font-size) | per-OS |
| `hypr` | Hyprland user overrides (bindings, input, monitors) | Omarchy |
| `omarchy-shell` | Omarchy shell config (shell.json, hooks, defaults) | Omarchy |
| `mise` | mise tool manifest (`config.toml`) | Omarchy |
| `keyd` | Hyper key (CapsLock = Hyper hold / Esc tap) | Omarchy |
| `fcitx5` | XCompose IME | Omarchy |
| `uwsm` | Desktop-session env | Omarchy |

### Shell (Zsh)

Modular configs sourced from `~/.zshrc`:

- `zsh/exports.zsh` — environment variables, PATH, tool init (pyenv, NVM lazy-load)
- `zsh/aliases.zsh` — aliases and utility functions
- `zsh/sources.zsh` — plugin sourcing (autosuggestions, syntax-highlighting)
- `zsh/hooks.zsh` — hooks (auto-ls on cd, git auto-pull on checkout main)
- `zsh/keys.zsh` — key bindings (alt-arrow word motion)
- `zsh/overrides.zsh` — zsh-compat wrappers for Omarchy's bash-indexed `tsl`/`hsl`
- `zsh/op.zsh` — 1Password-backed secret env

### Non-stowed Configs

Backed up manually or via `Taskfile.yml`:

- `macos/backups/` + `omarchy/backups/` — per-OS app backups (Antigravity, Zen, Raycast, Stats, 1Password)
- `macos/system/` — macOS system defaults + wallpaper

### Other

- `Brewfile` — Homebrew brews and casks
- `omarchy/Pkgfile` — Linux package list (yay)
- `global-agent-rules.md` — shared AI agent rules (symlinked to Claude, OpenCode, Gemini configs)
- `skills/` — AI agent workflow skills (`skills.yml` is the install source of truth)

## Private Dotfiles

Optional companion repo at `~/.dotfiles_private`. If present, `main.zsh` will stow its `ssh/` package and run its `main.zsh`. Shell configs also source `~/.dotfiles_private/zsh/private.zsh` if it exists.
