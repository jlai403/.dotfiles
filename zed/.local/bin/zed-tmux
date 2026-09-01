#!/bin/bash
export PATH="/opt/homebrew/bin:$PATH"
SESSION_NAME=$(pwd)
SESSION_NAME="${SESSION_NAME:-default}"
if [ -z "$TMUX" ]; then
  tmux new-session -A -s "$SESSION_NAME"
else
  exec zsh -i
fi
