#!/bin/sh
set -eu

HOME_CODE="$HOME/code"
HOME_PROJECTS="$HOME/projects"
HOME_DEV="$HOME/dev"
HOME_OPUS="$HOME/opus"
HOME_ROOT="$HOME"

die() {
  printf 'tmux-project: %s\n' "$*" >&2
  exit 1
}

command -v tmux >/dev/null || die "tmux is not installed"
command -v fzf  >/dev/null || die "fzf is not installed"

# Build the list of existing search dirs into a temp file so find(1) can use them.
DIRS_FILE="$(mktemp /tmp/tmux-project.XXXXXX)"
trap 'rm -f "$DIRS_FILE"' EXIT INT TERM

for dir in "$HOME_CODE" "$HOME_PROJECTS" "$HOME_DEV" "$HOME_OPUS" "$HOME_ROOT"; do
  [ -d "$dir" ] && printf '%s\n' "$dir" >> "$DIRS_FILE"
done

[ -s "$DIRS_FILE" ] || die "none of the search directories exist"

list_projects() {
  # xargs feeds the existing dirs to find; -d '\n' keeps paths with spaces safe.
  # FreeBSD find uses -E / ERE; no GNU extensions needed here.
  xargs find < "$DIRS_FILE" \
    -mindepth 1 \
    -maxdepth 4 \
    \( \
    -name .git       \
    -o -name node_modules \
    -o -name _build  \
    -o -name deps    \
    -o -name .cache  \
    -o -name .local  \
    -o -name vendor  \
    \) -type d -prune -o \
    -type d -print0 2>/dev/null |
    while IFS= read -r -d '' dir; do
      if  [ -d "$dir/.git"         ] ||
        [ -f "$dir/package.json" ] ||
        [ -f "$dir/mix.exs"      ] ||
        [ -f "$dir/go.mod"       ] ||
        [ -f "$dir/Cargo.toml"   ] ||
        [ -f "$dir/pyproject.toml" ] ||
        [ -f "$dir/Makefile"     ]; then
      printf '%s\n' "$dir"
      fi
    done |
      sed "s#^$HOME#~#" |
      sort -u
}

selected="$(
  list_projects | fzf --height=100% --border --prompt="project > "
  )" || exit 0

  [ -n "${selected:-}" ] || exit 0

# Expand ~ back to real path.
selected="${selected#\~}"
selected="$HOME$selected"

[ -d "$selected" ] || die "selected directory does not exist: $selected"

# Safe, unique tmux session name.
base="$(basename "$selected")"
slug="$(
  printf '%s' "$base"         |
    tr '[:upper:]' '[:lower:]'  |
    tr '. ' '__'                |
    tr -cd '[:alnum:]_-'
  )"
  # FreeBSD ships sha1(1), not sha1sum.
  hash="$(printf '%s' "$selected" | sha1 -q | cut -c1-8)"

  session_name="${slug:-project}_${hash}"

  if ! tmux has-session -t "=$session_name" 2>/dev/null; then
    tmux new-session -d -s "$session_name" -c "$selected"
  fi

  if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "=$session_name"
  else
    exec tmux attach-session -t "=$session_name"
  fi
