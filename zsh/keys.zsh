# Key bindings for herdr/terminal panes: mac-style Option (Alt) word motion.
# Mirrors inputrc for bash; zsh reads this module via the zshrc glob loop.
bindkey '\e[1;3C' forward-word
bindkey '\e[1;3D' backward-word
bindkey '\e[1;5C' forward-word
bindkey '\e[1;5D' backward-word
bindkey '\e[3;3~' kill-word
