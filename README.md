# Dotfiles

GNU Stow-based dotfiles for macOS (silicon Mac), [Omarchy](https://omarchy.org/) (Arch Linux on an Intel Mac), and Debian (headless dev LXCs). Configurations for Zsh, Neovim, Ghostty, Hyprland, tmux, and more. Uses three platform dirs — `macos/`, `omarchy/`, `debian/` — alongside a shared root layer.

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
| `--apps` | Install OS packages — `Brewfile` on macOS, `omarchy/Pkgfile` via yay on Omarchy (bootstraps `yay` if missing) — plus global bun packages |
| `--osx` | Apply macOS defaults (Dock, trackpad, keyboard, login items) |
| `--profile <name>` | Force a platform dir (`macos`, `omarchy`, `debian`) instead of detecting from the kernel and `/etc/os-release` |

On Omarchy, `./main.zsh` additionally runs `mise install` (tools declared in `omarchy/mise/.config/mise/config.toml`), sets the login shell to zsh (`sudo chsh -s /usr/bin/zsh`), and prepends the omarchy-zsh base to `~/.zshrc` (so completion, history, and omarchy's functions load).

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

## Architecture

Three layers, two mechanisms:

| Axis | Mechanism |
|------|-----------|
| shared ↔ OS | directory: repo root vs `macos/` / `omarchy/` / `debian/` |
| tracked ↔ machine-local | the repo vs `~/.dotfiles_private` |

`main.zsh` is a thin orchestrator. It picks `OS_DIR` (`macos`, `omarchy`, or `debian`; `--profile` overrides the `/etc/os-release` detection) — the only platform branch — and sources `lib/*.zsh` + `$OS_DIR/setup.zsh`, then runs a fixed pipeline. Platform behavior sits behind four hooks in `$OS_DIR/setup.zsh`:

- `_os_install_apps` — Homebrew (macOS) or yay + `Pkgfile` (Omarchy), both via `--apps`
- `_os_stow_packages` — package stows unique to the OS
- `_os_configure` — services, mise, Tailscale, privileged `/etc` stows
- `_os_finalize` — wallpaper + macOS defaults (`--osx`)

Shared steps live in `lib/shared.zsh` (`_stow_portable`, `_stow_gui`, `_link_zshrc`, `_setup_agents`, `_setup_ssh`, `_setup_private`); stow helpers in `lib/stow.zsh` (`_stow` for root packages, `_stow_platform` for the current OS dir). Root packages split in two: `_stow_portable` (every platform: `git`, `starship`, `inputrc`, `herdr`) runs from the main pipeline; `_stow_gui` (desktop terminals, editors, TUI apps) is called by `macos`/`omarchy` `_os_stow_packages`. Every `$OS_DIR` package — including the per-OS `ghostty`/`mise`/`ssh` overrides — is stowed from that OS's `_os_stow_packages`.

The shell mirrors this: shared `zsh/*.zsh` modules with **one OS file per OS** — `zsh/os/darwin.zsh` / `zsh/os/linux.zsh` / `zsh/os/debian.zsh` — each sourced if present, so the shared files contain no platform branching. `uname -s` is `Linux` for every distro, so `linux.zsh` dispatches to `debian.zsh` when `/etc/os-release` is not Arch. `typeset -U PATH` keeps prepends deduped across re-sources and nested shells.

## Structure

### Stow Packages

Symlinked to home/config directories via GNU Stow. Root packages stow on every platform; `macos/` and `omarchy/` packages are platform-gated. `debian/` holds the headless platform: the `mise` manifest stowed to `~/.config/mise/config.toml`, the SSH append, and the four `_os_*` hooks.

| Package | What it configures | Platform |
|---------|--------------------|----------|
| `aerospace` | Tiling window manager | macOS |
| `borders` | Window border highlight | macOS |
| `cliamp` | Spotify TUI | desktop |
| `ghostty` | Terminal emulator — shared base config + per-OS `local.conf` | desktop |
| `git` | Git global config | all |
| `herdr` | Terminal multiplexer | all |
| `inputrc` | Readline keybindings | all |
| `nvim` | Neovim colorscheme (baseline comes from omarchy-nvim) | desktop |
| `opencode` | OpenCode AI tool | desktop |
| `ssh` | SSH config (1Password agent socket; Omarchy also adds `ghjlai`/`ghstellar`/`forgejo` host aliases) | per-OS |
| `television` | TUI fuzzy finder | desktop |
| `tmux` | Tmux | desktop |
| `zed` | Zed editor (Tokyo Night vendored; keymap per-OS) | desktop |
| `ghostty` | Ghostty `local.conf` overrides (macOS keybinds/font, Omarchy include + font-size) | per-OS |
| `hypr` | Hyprland user overrides (bindings, input, monitors) | Omarchy |
| `omarchy-shell` | Omarchy shell config (shell.json, hooks, defaults) | Omarchy |
| `mise` | mise tool manifest (`config.toml`) | Omarchy, Debian |
| `keyd` | Hyper key (CapsLock = Hyper hold / Esc tap) | Omarchy |
| `fcitx5` | XCompose IME | Omarchy |
| `uwsm` | Desktop-session env | Omarchy |

### Shell (Zsh)

Modular configs sourced from `~/.zshrc`:

- `zsh/os/darwin.zsh` / `zsh/os/linux.zsh` — the only OS-aware shell files (PATH, SSH agent, Homebrew/mise, plugin dirs, mac-only aliases); sourced if present
- `zsh/exports.zsh` — environment variables, PATH, tool init (pyenv, NVM lazy-load)
- `zsh/aliases.zsh` — aliases and utility functions
- `zsh/sources.zsh` — plugin sourcing (autosuggestions, syntax-highlighting)
- `zsh/hooks.zsh` — hooks (auto-ls on cd, git auto-pull on checkout main)
- `zsh/keys.zsh` — key bindings (alt-arrow word motion)
- `zsh/overrides.zsh` — zsh-compat wrappers for Omarchy's bash-indexed `tsl`/`hsl`
- `zsh/op.zsh` — 1Password-backed secret env (resolved lazily on use, e.g. by the `cliamp()` wrapper)

### Non-stowed Configs

Backed up manually or via `Taskfile.yml`:

- `macos/backups/` + `omarchy/backups/` — per-OS app backups (Antigravity, Zen, Raycast, Stats, 1Password)
- `macos/system/` — macOS system defaults + wallpaper

### Other

- `Brewfile` — Homebrew brews and casks
- `omarchy/Pkgfile` — Linux package list (yay)
- `global-agent-rules.md` — shared AI agent rules (symlinked to Claude, OpenCode, Gemini configs)
- AI agent skills, defined in the separate [jlai403/skills](https://github.com/jlai403/skills) repo; `lib/shared.zsh` runs its installer, nothing is tracked here

## Private Dotfiles

Optional companion repo at `~/.dotfiles_private`. If present, `main.zsh` will stow its `ssh/` package and run its `main.zsh`. Shell configs also source `~/.dotfiles_private/zsh/private.zsh` if it exists.
