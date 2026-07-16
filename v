#!/usr/bin/env bash
# v - neovim session manager / lightweight multiplexer replacement
set -euo pipefail

required_tools=(nvim pstree realpath fzf ss git find column)
missing=()
for tool in "${required_tools[@]}"; do
    command -v "$tool" &>/dev/null || missing+=("$tool")
done
if [ "${#missing[@]}" -ne 0 ]; then
    echo "$0: error: missing required tools: ${missing[*]}" >&2
    exit 1
fi

SOCK_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/v/sockets"
mkdir -p "$SOCK_DIR"

# Where to look for "not yet open" projects when jumping. Edit to taste.
PROJECT_ROOTS=("$HOME/code" "$HOME/projects" "$HOME/dev")
PROJECT_DEPTH=3

# ---- helpers -----------------------------------------------------------

# all live nvim server sockets, found by process name (not by path,
# so custom --listen names still work)
live_sockets() {
    ss -xlp 2>/dev/null | awk '$0 ~ /"nvim"/ { print $5 }' | while IFS= read -r s; do
        [ -S "$s" ] && printf '%s\n' "$s"
    done
}

# name for a socket: filename minus .sock if it lives in our SOCK_DIR,
# otherwise fall back to the raw socket basename
sock_name() {
    local sock=$1 base
    base=$(basename -- "$sock")
    case "$sock" in
        "$SOCK_DIR"/*) printf '%s\n' "${base%.sock}" ;;
        *) printf '%s\n' "$base" ;;
    esac
}

sock_cwd() {
    nvim --server "$1" --remote-expr 'getcwd()' 2>/dev/null
}

sock_pid() {
    nvim --server "$1" --remote-expr 'getpid()' 2>/dev/null
}

# listening tcp ports owned by any descendant of a given pid
sock_ports() {
    local pid=$1 pids
    pids=$(pstree -p "$pid" 2>/dev/null | grep -oP '\(\K[0-9]+(?=\))') || true
    [ -z "$pids" ] && return
    # shellcheck disable=SC2086
    ss -ltnp 2>/dev/null | grep -F -f <(printf 'pid=%s,\n' $pids) 2>/dev/null \
        | awk '{print $4}' | awk -F: '{print $NF}' | sort -un | paste -sd, -
}

# project name for a directory: git repo name if inside one, else basename
project_name() {
    local dir=$1 root
    root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || true
    basename -- "${root:-$dir}"
}

sanitize() { tr -c 'A-Za-z0-9_.-' '_' <<< "$1"; }

# ---- socket-derived listing ---------------------------------------------

list_line() {
    local sock=$1 cwd name pid ports
    cwd=$(sock_cwd "$sock") || return 0
    [ -n "$cwd" ] || return 0
    name=$(sock_name "$sock")
    pid=$(sock_pid "$sock")
    ports=$(sock_ports "$pid")
    printf 'live\t%s\t%s\t%s\t%s\n' "$name" "${ports:--}" "$cwd" "$sock"
}

if [[ "${1:-}" =~ ^-l$|^--list$ ]]; then
    live_sockets | while IFS= read -r sock; do
        list_line "$sock"
    done | column -t -s $'\t'
    exit
fi

if [[ "${1:-}" =~ ^-k$|^--kill$ ]]; then
    sock=$(live_sockets | while IFS= read -r s; do list_line "$s"; done \
        | fzf --delimiter='\t' --with-nth=2,3,4 | cut -f5)
    [ -S "$sock" ] || { echo "$0: error: nothing selected" >&2; exit 1; }
    nvim --server "$sock" --remote-send '<Esc>:qa!<CR>'
    exit
fi

# ---- unified jump: live sessions + not-yet-open projects ---------------

if [[ "${1:-}" =~ ^-j$|^--jump$ ]]; then
    live=$(live_sockets | while IFS= read -r s; do list_line "$s"; done)
    live_cwds=$(printf '%s\n' "$live" | cut -f4)

    candidates=""
    for root in "${PROJECT_ROOTS[@]}"; do
        [ -d "$root" ] || continue
        while IFS= read -r d; do
            grep -qxF "$d" <<< "$live_cwds" && continue
            printf -v line 'new\t%s\t-\t%s\t-\n' "$(project_name "$d")" "$d"
            candidates+="$line"
        done < <(find "$root" -mindepth 1 -maxdepth "$PROJECT_DEPTH" -type d -name .git -printf '%h\n' 2>/dev/null)
    done

    picked=$(printf '%s%s' "$live" "$candidates" \
        | fzf --delimiter='\t' --with-nth=1,2,3,4 \
              --header='kind  name  ports  cwd')
    [ -n "$picked" ] || exit 1

    kind=$(cut -f1 <<< "$picked")
    cwd=$(cut -f4 <<< "$picked")

    if [ "$kind" = live ]; then
        sock=$(cut -f5 <<< "$picked")
        nvim --server "$sock" --remote-ui
    else
        name=$(sanitize "$(project_name "$cwd")")
        sock="$SOCK_DIR/$name.sock"
        [ -S "$sock" ] && sock="$SOCK_DIR/$name-$$.sock"
        (cd "$cwd" && nvim --listen "$sock" +terminal --startuptime /tmp/nvimstartup)
    fi
    exit
fi

# ---- named session creation ---------------------------------------------

name=""
if [[ "${1:-}" =~ ^-n$|^--name$ ]]; then
    name=${2:-}
    [ -n "$name" ] || { echo "$0: error: --name requires a value" >&2; exit 1; }
    shift 2
fi

attach="false"
if [[ "${1:-}" =~ ^-a$|^--attach$ ]]; then
    attach="true"
    shift
fi

# a single directory argument only makes sense as "start the session here",
# never as a file to edit (that's what triggers netrw). Peel it off before
# the file-args guard below, but only when we're creating a new session.
start_dir=""
if [ "$attach" != "true" ] && [ "$#" -eq 1 ] && [ -d "$1" ]; then
    start_dir=$1
    shift
fi

for arg in "$@"; do
    if [ -d "$arg" ]; then
        echo "$0: error: '$arg' is a directory" >&2
        exit 1
    fi
done

if pstree -s $$ | grep -q nvim; then
    if [ "$attach" = "true" ]; then
        echo "$0: error: cannot attach: already inside neovim" >&2
        exit 1
    fi
    if [ "$#" -ne 0 ]; then
        realpath --zero "$@" | xargs -0 -n1 nvim --server "$NVIM" --remote
    fi
    exit
fi

if [ "$attach" != "true" ]; then
    listen_args=()
    if [ -n "$name" ]; then
        sock="$SOCK_DIR/$(sanitize "$name").sock"
        [ -S "$sock" ] && { echo "$0: error: session '$name' already exists ($sock)" >&2; exit 1; }
        listen_args=(--listen "$sock")
    fi
    if [ -n "$start_dir" ]; then
        cd "$start_dir" || exit 1
    fi
    if [ "$#" -eq 0 ]; then
        nvim "${listen_args[@]}" +terminal --startuptime /tmp/nvimstartup
    else
        nvim "${listen_args[@]}" "$@" --startuptime /tmp/nvimstartup
    fi
    exit
fi

# --attach with no --name: fall back to picking any live socket
sockets=$(live_sockets)
[ -n "$sockets" ] || { echo "$0: error: no neovim sockets found" >&2; exit 1; }
entries=""
while IFS= read -r sock; do
    cwd=$(sock_cwd "$sock") || continue
    [ -n "$cwd" ] || continue
    entries+=$(printf '%s\t%s\t%s\n' "$sock" "$(sock_name "$sock")" "$cwd")$'\n'
done <<< "$sockets"
[ -n "$entries" ] || { echo "$0: error: no live neovim sockets found" >&2; exit 1; }

selected=$(printf '%s' "$entries" | fzf --delimiter='\t' --with-nth=2,3 | cut -f1)
[ -S "$selected" ] || { echo "$0: error: selection is not a neovim socket" >&2; exit 1; }
nvim --server "$selected" --remote-ui
