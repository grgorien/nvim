#!/usr/bin/env bash
set -euo pipefail

SEARCH_DIRS=(
  "$HOME/code"
  "$HOME/projects"
  "$HOME/dev"
  "$HOME"
)

die() {
  printf 'tmux-project: %s\n' "$*" >&2
  exit 1
}

command -v tmux >/dev/null || die "tmux is not installed"
command -v fzf >/dev/null || die "fzf is not installed"

# Keep only search dirs that actually exist.
existing_dirs=()
for dir in "${SEARCH_DIRS[@]}"; do
  [[ -d "$dir" ]] && existing_dirs+=("$dir")
done

((${#existing_dirs[@]} > 0)) || die "none of the search directories exist"

list_projects() {
  find "${existing_dirs[@]}" \
    -mindepth 1 \
    -maxdepth 4 \
    \( \
    -name .git \
    -o -name node_modules \
    -o -name _build \
    -o -name deps \
    -o -name .cache \
    -o -name .local \
    -o -name vendor \
    \) -type d -prune -o \
    -type d -print0 2>/dev/null |
    while IFS= read -r -d '' dir; do
      if [[ 
        -d "$dir/.git" ||
        -f "$dir/package.json" ||
        -f "$dir/mix.exs" ||
        -f "$dir/go.mod" ||
        -f "$dir/Cargo.toml" ||
        -f "$dir/pyproject.toml" ||
        -f "$dir/Makefile" ]] \
        ; then
        printf '%s\n' "$dir"
      fi
    done |
    sed "s#^$HOME#~#" |
    sort -u
}

selected="$(
  list_projects |
    fzf --height=100% --border --prompt="project > "
)" || exit 0

[[ -n "${selected:-}" ]] || exit 0

# Expand ~ back to real path.
selected="${selected/#\~/$HOME}"

[[ -d "$selected" ]] || die "selected directory does not exist: $selected"

# Safe, unique tmux session name.
base="$(basename "$selected")"
slug="$(
  printf '%s' "$base" |
    tr '[:upper:]' '[:lower:]' |
    tr '. ' '__' |
    tr -cd '[:alnum:]_-'
)"

hash="$(printf '%s' "$selected" | sha1sum | cut -c1-8)"
session_name="${slug:-project}_${hash}"

# Create the session if missing.
# The = prefix forces exact tmux session matching.
if ! tmux has-session -t "=$session_name" 2>/dev/null; then
  tmux new-session -d -s "$session_name" -c "$selected"
fi

# Inside tmux: switch the current client.
# Outside tmux: attach normally.
if [[ -n "${TMUX:-}" ]]; then
  tmux switch-client -t "=$session_name"
else
  exec tmux attach-session -t "=$session_name"
fi
