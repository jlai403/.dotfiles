---
name: add-stow-package
description: Use when adding a new application's dotfile config to this GNU stow dotfiles repo
---

# Add Stow Package

## Overview

This repo uses `stow -v <pkg>` (via the `_stow` helper in `main.zsh`) run from `~/.dotfiles/`. Stow creates symlinks by mirroring the package's directory structure relative to `~`. Each top-level directory in the repo is a stow package.

## Config Location Patterns

| Pattern | Apps | Target path | Package structure |
|---|---|---|---|
| XDG config | nvim, ghostty, git, starship, tmux (future) | `~/.config/<app>/` | `<app>/.config/<app>/` |
| Home-root dotfile | tmux, aerospace | `~/.<file>` | `<app>/.<file>` |

Most modern apps use XDG. Check the app's docs or `man` page if unsure.

## Steps

1. **Identify the target path** — where the app reads its config from (`~/.config/<app>/` or `~/.<file>`)

2. **Create the package directory** at the dotfiles root:
   ```zsh
   mkdir -p ~/.dotfiles/<appname>
   ```

3. **Mirror the target path** inside the package:
   ```zsh
   # XDG pattern:
   mkdir -p ~/.dotfiles/<appname>/.config/<appname>

   # Home-root pattern:
   # (no subdirs needed, file goes directly in ~/.dotfiles/<appname>/)
   ```

4. **Move or create the config file(s)** into the mirrored structure:
   ```zsh
   # If config already exists at target:
   mv ~/.config/<appname>/config ~/.dotfiles/<appname>/.config/<appname>/config

   # If starting fresh, create the file directly in the mirrored path
   ```
   Stow will refuse to create a symlink if the target file already exists — move it first.

5. **Add `.stow-local-ignore`** if the package dir contains non-config files (scripts, `*.append` prepend files, or `.git` artifacts). One pattern per line, regex syntax:
   ```
   \.DS_Store
   .*\.append
   ```

6. **Add `_stow <appname>` to `main.zsh`** in the appropriate block:
   - Core app configs: the block starting with `_stow aerospace` (apps like ghostty, git, nvim, tmux)
   - AI tool configs: the block starting with `_stow opencode` (opencode, gemini)
   - Add alphabetically within the block

7. **Run stow** from the dotfiles root using the repo's helper:
   ```zsh
   cd ~/.dotfiles
   _stow <appname>
   ```
   `_stow` wraps `stow -v` and prints a confirmation message on success.

8. **Verify** the symlinks point correctly:
   ```zsh
   ls -la ~/.config/<appname>/
   # or for home-root:
   ls -la ~/.<file>
   ```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Running `stow` from wrong directory | Must run from `~/.dotfiles/`, not `~` or the package dir |
| Target file already exists | `mv` it into the package structure first |
| Missing parent directory at target | `mkdir -p ~/.config/<appname>` before stowing if needed |
| Package dir nested one level wrong | `<app>/.config/<app>/file` not `<app>/config/<app>/file` |
| Calling `stow <app>` directly | Use `_stow <app>` — it's the repo's helper and prints confirmation |
