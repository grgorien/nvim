# v - a tmux-shaped hole filled with neovim 12

`v` is a single bash script that manages neovim instances as if they were
tmux sessions: named, listable, killable, fuzzy-jumpable, and attachable
from anywhere. There is no multiplexer daemon. There is no `.tmux.conf`.
There is a `--listen <socket>` and `ss` grepping for who's holding it open.

Read the **Mental model** section before you use this for anything you
care about — it is the part that differs from tmux in a way that will
bite you if you assume otherwise.

## Requirements

```
nvim pstree realpath fzf ss git find column
```

The script checks for all of these on startup and refuses to run if any
are missing.

## Installation

```sh
lnstall -Dm755 v ~/.config/nvim/v
# make sure x is on path is on PATH
```

Sockets live under `${XDG_STATE_HOME:-$HOME/.local/state}/v/sockets`.
Edit `PROJECT_ROOTS` and `PROJECT_DEPTH` at the top of the script to
match where your projects actually live — this drives `v -j`.

## Mental model: there is no server, only a process

tmux has a real daemon. A pane can be killed, the client detaches, the
daemon keeps the shell alive regardless of what spawned it.

`v` has none of that. `v -n foo` runs a completely ordinary
`nvim --listen $SOCK ...` in the foreground of whatever terminal you ran
it from. It is not `--headless`. It is not backgrounded. It is not
disowned. If that terminal dies, the session dies with it (SIGHUP).

So "detaching" in `v` doesn't mean what it means in tmux — there is no
detach command, because there is nothing to detach *from* on the server
side. What you're actually doing when you "detach" is:

- closing the **client** (the `--remote-ui` window), which is fine, or
- leaving the **founding terminal** running somewhere you won't close it.

**Do**, if you want a session to survive:

```sh
setsid v -n foo </dev/null &>/dev/null & disown
```

or start it in a terminal window you deliberately park and ignore, or
run it under a service manager (systemd user unit, a dedicated always-on
terminal tab, whatever). The socket is just a side effect of the nvim
process being alive — keep the process alive by whatever means you'd
keep any other long-running foreground job alive.

**Don't** assume closing the terminal that ran `v -n foo` leaves the
session running. It won't, unless you disowned it first.

## Detaching a `--remote-ui` client (the safe way)

`v -j` and the fallback of `v -a` both attach with:

```sh
nvim --server "$sock" --remote-ui
```

This makes your terminal a **UI client** of the remote nvim — every
keystroke you send is being executed by the remote instance, including
`:q` and `:qa`.

**Do not** run `:q`, `:qa`, `:qa!`, or `ZZ` in every window just to "step
away" — that quits the *server*, killing the session for anyone/anything
else attached to it, not just your view.

**Do**, to detach without killing the session: close the client the way
you'd close any terminal window — `Ctrl-Shift-w`, close the tab, kill the
terminal emulator, or `Ctrl-z` the client process and `kill %1` it from
elsewhere. The remote nvim keeps running because your client exiting is
just a TCP/socket peer disconnecting — the server doesn't care.

Only use `v -k` / `--kill` when you actually mean to end the session.
Note that it sends `<Esc>:qa!<CR>` — the `!` means **no save prompts,
unsaved buffers are discarded silently**. Save before you kill.

## Commands

```
v                          # inside a :terminal buffer with no args: no-op
v file.py [file2.py ...]   # inside a :terminal buffer: opens files in the
                            # *parent* nvim via $NVIM, doesn't nest
v dir/                     # outside nvim, new session: cd's into dir/, no file args
v file.py [file2.py ...]   # outside nvim, new session: nvim on those files
v -n NAME [file ...]       # new named, addressable session
v -a, --attach             # fuzzy-pick any live session, attach --remote-ui
v -j, --jump               # fuzzy-pick a live session OR an unopened git
                            # project under $PROJECT_ROOTS; opens whichever
v -l, --list                # table of live sessions: name, ports, cwd, socket
v -k, --kill                # fuzzy-pick a live session, force-quit it (no save)
```

### Examples

```sh
# start a named session for a project
cd ~/code/cordwainer && v -n cordwainer

# from any shell, anywhere: reattach to it
v -a                      # fuzzy list, pick cordwainer

# jump straight to a project you haven't even opened yet
v -j                      # shows live sessions + git repos under
                           # ~/code ~/projects ~/dev not yet running

# check what's alive and what ports its :terminal children are holding
v -l

# already inside nvim's :terminal, want to edit a file in *this* session
v somefile.go              # opens in current session, doesn't nest nvim

# done for the day, want it gone (make sure you saved first)
v -k
```

## What `-n`/`--name` actually buys you

A named socket is just a predictable path
(`$SOCK_DIR/<sanitized-name>.sock`) instead of an unnamed/anonymous one.
It exists so you can reason about *which* session is which in `v -l` and
so re-running `v -n foo` while `foo` is still alive fails loudly
(`session 'foo' already exists`) instead of silently spawning a second,
confusingly-identical session.

**Known gap:** `--attach --name foo` does **not** currently attach to the
socket named `foo` specifically — the attach path always falls through
to a generic fuzzy-pick over *all* live sockets, ignoring `--name`
entirely. If you want a specific named session, use `v -j` or `v -a` and
pick it by eye in the fzf list, not `-a -n foo`.

## Directory- and file-argument rules

- Exactly one bare directory argument, only when *creating* a new
  session (not `--attach`), is treated as "start the session here" — it
  `cd`s into it, no file is opened, netrw never shows up.
- Any *other* directory passed as an argument is an error, on purpose.
  This exists specifically so netrw never opens by accident when you
  fat-finger a path. Don't expect `v somedir/ otherdir/` to work — it
  will refuse.
- Multiple file arguments are realpath'd and opened; if you're already
  inside a `:terminal`, they're sent one at a time to the parent session
  via `--remote`, not batch-opened.

## Vim motions in the fzf pickers

Every picker in `v` (`-l`, `-k`, `-j`, `-a`) is plain `fzf` with no
special bindings baked into the script — navigation is whatever your
`FZF_DEFAULT_OPTS` says it is. Out of the box fzf only binds
`Ctrl-n`/`Ctrl-p` for down/up, **not** `j`/`k`. If you want real vim
motions in the picker, set this in your shell rc:

```sh
export FZF_DEFAULT_OPTS='
  --bind=ctrl-j:down,ctrl-k:up
  --bind=ctrl-d:half-page-down,ctrl-u:half-page-up
  --bind=ctrl-f:page-down,ctrl-b:page-up
  --bind=/:show-preview
'
```

`fzf` reserves plain `j`/`k` for the query text (it's a filter-as-you-type
tool, not a modal one), so the usual convention is `Ctrl`-prefixed motions
as above rather than bare `hjkl`. Apply this once globally and every `v`
picker inherits it — there's nothing to configure per-command.

## Do / Don't summary

| | Do | Don't |
|---|---|---|
| Persistence | `setsid ... & disown`, or a dedicated terminal you never close | assume closing the launching terminal leaves the session alive |
| Leaving a session | close the `--remote-ui` client terminal/window | run `:q`/`:qa` inside an attached client to "step away" |
| Ending a session | `v -k`, after saving | `v -k` expecting it to prompt you — it force-quits (`:qa!`) |
| Reattaching by name | `v -j` or `v -a`, pick by eye | `v -a --name foo` — `--name` is ignored on attach |
| Opening a file from inside `:terminal` | `v file.py` — routes to the parent session via `$NVIM` | run a second `v -n ...` from inside a `:terminal` expecting nesting to work cleanly |
| Directories as args | one only, only on session creation, to set cwd | pass a directory expecting it to open in netrw — it's rejected by design |

## Debugging

Every launched nvim writes `--startuptime /tmp/nvimstartup`, so slow
startup on a given session is a `cat /tmp/nvimstartup` away, no separate
profiling invocation needed.
