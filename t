#!/usr/bin/env bash
set -euo pipefail

SEARCH_DIRS=(
  "$HOME/code"
  "$HOME/projects"
  "$HOME/dev"
  "$HOME/opus"
  "$HOME"
)

# Find project directories.
selected="$(
  find "${SEARCH_DIRS[@]}" \
    -mindepth 1 \
    -maxdepth 3 \
    -type d \
    \( -name .git -o -name node_modules -o -name _build -o -name deps \) -prune -o \
    -type d \
    -print 2>/dev/null |
  sed "s#^$HOME#~#" |
  sort -u |
  fzf --height 100% --border --prompt="project > "
)"

[ -z "${selected:-}" ] && exit 0

# Expand ~ back to home.
selected="${selected/#\~/$HOME}"

# Safe tmux session name.
session_name="$(basename "$selected" | tr . _ | tr -cd '[:alnum:]_-')"

# Create session if it does not exist.
if ! tmux has-session -t "$session_name" 2>/dev/null; then
  tmux new-session -ds "$session_name" -c "$selected"
fi

# If already inside tmux, switch. Otherwise attach.
if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "$session_name"
else
  tmux attach-session -t "$session_name"
fi
