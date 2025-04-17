# Dotfiles

This repository contains my personal configuration files (dotfiles) for macOS. It includes settings for Zsh, Neovim, and other tools I use daily.

## Installation

1. Clone this repository to your home directory:

   ```bash
   git clone https://github.com/jlai403/dotfiles.git ~/.dotfiles
   ```

2. Navigate to the cloned directory:

   ```bash
   cd ~/.dotfiles
   ```

3. Run the `main.zsh` script to set up the dotfiles:

   ```bash
   ./main.zsh
   ```

   This script will:
   - Install applications and tools using Homebrew.
   - Update your `~/.zshrc` file to load custom Zsh configurations and the Starship prompt.
   - Create a symlink for Neovim configuration.
   - Enable press-and-hold for special characters in VSCode.

## Structure

- `zsh/`: Contains Zsh configuration files, such as aliases and exports.
- `nvim/`: Neovim configuration files.
- `Brewfile`: List of Homebrew packages to install.
- `main.zsh`: Main setup script.

## Notes

- Ensure you have Homebrew installed before running the setup script. You can install it from [brew.sh](https://brew.sh/).
- The script assumes macOS as the operating system.

Feel free to customize the configurations to suit your needs!