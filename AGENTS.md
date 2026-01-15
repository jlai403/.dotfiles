# AGENTS.md
> **INSTRUCTION:** Combine the project specifics below with the coding standards in `./.agent/AI_RULES.md`.

## Build/Test Commands
- Test setup script: Run `./main.zsh` in a clean environment or VM
- Verify changes: Check symlinks with `ls -la ~ | grep -E '\.dotfiles'`
- Backup configs before testing: `cp ~/.zshrc ~/.zshrc.backup`

## Code Style Guidelines

### Shell Scripts (Zsh)
- Use snake_case for function names
- Define color constants at file top (RED, GREEN, etc.)
- Check file existence before modifications
- Use echo with color codes for user feedback
- Create backups before overwriting files

### Lua (Neovim configs)
- Use local variable declarations
- Follow LazyVim plugin specification format
- Use table.extend for config merging
- Minimal comments, only when necessary

### General
- No trailing whitespace
- Consistent indentation (2 spaces for Lua, tabs for shell)
- Test in isolated environment before committing
