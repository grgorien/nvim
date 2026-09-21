# v

A small Bash session manager for Neovim.

`v` makes it practical to keep multiple Neovim processes running, find them with `fzf`, and reconnect to them from another terminal.

The idea is simple:

> **Neovim is the session. The Unix socket is only the address used to connect to it.**

`v` does not run a daemon. It does not create another session server. It does not try to become tmux.

Instead, it uses Neovim's existing `--listen` and `--remote-ui` functionality and adds a small amount of Bash around it.

The result is a workflow where Neovim remains the center of the environment:

* Vim motions are always available
* buffers remain the main unit of open files
* `fzf` handles file finding, grep, buffers, and session selection
* LSP navigation stays inside the editor
* an embedded terminal is available when needed
* multiple terminals can connect to the same Neovim process
* projects can be discovered and started without remembering commands
* there is no separate session daemon to understand

The goal is not to reproduce every feature of tmux.

The goal is to make **Neovim itself the place where the work lives**.

## Repository

This repository is also the Neovim configuration directory.

```text
~/.config/nvim/
├── init.lua
├── nvim-pack-lock.json
├── v
├── README.md
└── .gitignore
```

### `v`

The Bash script that manages Neovim processes and their Unix sockets.

### `init.lua`

The Neovim configuration.

### `nvim-pack-lock.json`

The lockfile for Neovim's built-in package system.

The `v` command is exposed through a symlink:

```text
/usr/local/bin/v
        |
        v
~/.config/nvim/v
```

There is only one copy of the script.

The repository contains the real file. `/usr/local/bin/v` simply makes that file available as a normal command.

# Why this exists

A normal terminal workflow tends to become fragmented.

You may have:

```text
terminal
terminal
terminal
browser
editor
terminal
```

and eventually some kind of multiplexer is needed to keep those processes organized.

`v` takes a different approach.

The editor already provides a lot of the things needed for development:

```text
Neovim
├── buffers
├── windows
├── tabs
├── Vim motions
├── LSP
├── grep
├── file finding
├── terminal
└── plugins
```

With `fzf` and the Neovim configuration in this repository, most navigation can happen without leaving the editor.

For example:

```text
find a file
    |
    +--> fzf
    |
    +--> open buffer
    |
    +--> Vim motions
    |
    +--> edit
```

Or:

```text
search for text
    |
    +--> grep
    |
    +--> fzf
    |
    +--> open matching line
    |
    +--> continue editing
```

Or:

```text
find another running project
    |
    +--> v -j
    |
    +--> fzf
    |
    +--> remote-ui
    |
    +--> existing Neovim session
```

The important part is that these operations converge on the same thing:

> **the Neovim process.**

Instead of constantly moving between separate terminal tools, the editor becomes the workspace and the terminal becomes one of its tools.

# Mental model

This is the most important section of the README.

If you understand this, the rest of `v` is straightforward.

## There is no `v` server

A program such as tmux has a server.

Conceptually:

```text
terminal
   |
   v
tmux client
   |
   v
tmux server
   |
   +-- shell
   +-- shell
   +-- shell
```

The tmux server owns the sessions.

The terminal client can disappear and the server can continue running.

`v` does not work this way.

When you run:

```sh
v -n project
```

`v` starts an ordinary Neovim process:

```sh
nvim --listen /path/to/project.sock
```

That Neovim process is the session.

There is no `v` server sitting behind it.

Think:

```text
terminal
   |
   v
 v script
   |
   v
 nvim
   |
   v
project.sock
```

The script starts the process, does whatever work is necessary, and then exits.

The Neovim process is what remains.

## What the socket is

The socket is an address.

It is not the session.

Imagine calling a person on the telephone.

The telephone number is not the person. It is how you reach the person.

The Unix socket works similarly:

```text
Unix socket
     |
     v
"Where can I reach this Neovim?"
     |
     v
Neovim process
```

When Neovim starts with:

```sh
nvim --listen /path/to/project.sock
```

it begins listening for other Neovim processes.

Another terminal can then run:

```sh
nvim --server /path/to/project.sock --remote-ui
```

That second Neovim process is acting as a UI client for the first one.

There is still only one actual Neovim session.

## One process, multiple terminals

The relationship looks like this:

```text
                         Neovim process
                         THE SESSION
                              |
                       project.sock
                              |
              +---------------+---------------+
              |                               |
       original terminal                remote terminal
              |                               |
              |                         --remote-ui
              |                               |
              +---------------+---------------+
                              |
                       same Neovim state
```

Both terminals are interacting with the same editor.

The buffers, windows, cursor positions, undo state, LSP state, and everything else belong to the same Neovim process.

# The important difference from tmux

The original terminal that starts Neovim matters.

Suppose:

```text
Terminal A
    |
    v
v -n project
    |
    v
Neovim
```

Terminal A owns the shell that launched Neovim.

If Terminal A closes, the shell can send `SIGHUP` to its child processes.

Neovim may therefore exit.

If Neovim exits, the session is gone.

There is no `v` daemon that takes ownership of it.

This means:

> **A `v` session is only as persistent as the Neovim process itself.**

If the process must survive the terminal that started it, you need to detach it from that terminal yourself.

For example:

```sh
setsid v -n project </dev/null &>/dev/null & disown
```

Or simply leave the original terminal open.

Or run it under a service manager.

`v` does not care how you keep the process alive.

## Why there is no detach command

In tmux, "detach" makes sense because a client is connected to a server.

With `v`, there is no separate session server.

When you run:

```sh
nvim --server project.sock --remote-ui
```

you are opening a UI client connected to an existing Neovim process.

Therefore, leaving the session means closing the UI client.

For example:

```text
close terminal
     |
     v
remote UI disappears
     |
     v
Neovim process may continue
```

There is no special `v detach` operation because there is nothing server-side that needs to be detached from.

# Attaching safely

`v -a` and `v -j` eventually use:

```sh
nvim --server "$sock" --remote-ui
```

Once attached, your terminal is controlling the actual Neovim process.

This distinction is critical.

If you type:

```vim
:q
```

you are not telling the terminal:

> "Disconnect me."

You are telling Neovim:

> "Quit."

The same applies to:

```vim
:qa
:qa!
ZZ
```

These operate on the actual Neovim process.

Therefore:

```text
:q
 |
 v
Neovim exits
 |
 v
session is gone
```

Whereas:

```text
close terminal
 |
 v
remote UI disconnects
 |
 v
Neovim can remain alive
```

To leave an attached session, close the terminal or terminal tab running the remote UI.

To actually destroy the session, use:

```sh
v -k
```

# Session lifecycle

A complete session looks like this:

```text
1. CREATE

   v -n project
        |
        v
      nvim
        |
        +--> project.sock


2. ATTACH

   v -a
     |
     v
    fzf
     |
     v
   project.sock
     |
     v
   nvim --server project.sock --remote-ui
     |
     v
   existing Neovim


3. LEAVE

   close remote terminal
        |
        v
   remote UI exits
        |
        v
   Neovim may continue running


4. KILL

   v -k
     |
     v
   choose session
     |
     v
   :qa!
     |
     v
   Neovim exits
```

The socket is simply the connection point throughout this lifecycle.

# Socket storage

Sockets are stored under:

```sh
${XDG_STATE_HOME:-$HOME/.local/state}/v/sockets
```

Normally this means:

```text
~/.local/state/v/sockets/
```

You may see:

```text
~/.local/state/v/sockets/
├── project.sock
├── notes.sock
└── another-project.sock
```

Do not think of these files as saved sessions.

They are addresses for currently running Neovim processes.

A socket existing on disk does not by itself prove that the corresponding Neovim process is alive.

That is why `v` checks the actual system state rather than treating filenames as truth.

# Installation

This repository is intended to live at:

```text
~/.config/nvim
```

The repository itself contains the Neovim configuration and the `v` script.

After placing the repository there, make the script executable:

```sh
chmod +x ~/.config/nvim/v
```

Then expose it through your normal `$PATH`:

```sh
sudo ln -sf ~/.config/nvim/v /usr/local/bin/v
```

Verify:

```sh
which v
```

You should get:

```text
/usr/local/bin/v
```

Then:

```sh
ls -la "$(which v)"
```

should show a symlink conceptually like:

```text
/usr/local/bin/v -> /home/USER/.config/nvim/v
```

The exact username and path will depend on the machine.

This setup is deliberate.

There is no:

```text
/usr/local/bin/v        copied script
~/.config/nvim/v        another script
```

There is only:

```text
~/.config/nvim/v        actual script
        ^
        |
/usr/local/bin/v        symlink
```

That means editing the repository's `v` immediately changes the command you run.

# Requirements

`v` requires:

```text
nvim
pstree
realpath
fzf
ss
git
find
column
```

The script checks for required commands when it starts.

Optional tools used by the shell helpers include:

```text
rg
bat
```

`vg` falls back to `grep` when `rg` is unavailable.

`bat` is only used to make previews nicer. `cat` is the fallback.

# Configuration

There is intentionally very little configuration.

Near the top of `v` are:

```sh
PROJECT_ROOTS
PROJECT_DEPTH
```

These tell `v -j` where to search for Git projects.

Set them to directories containing your own projects.

Do not put personal project names into this README.

The script should contain the machine-specific paths. The README only documents what those settings mean.

# Commands

```text
v                         inside :terminal: no-op

v file.py [file2 ...]     inside :terminal:
                          open files in the parent Neovim

v dir/                    outside Neovim:
                          start a session in this directory

v file.py [file2 ...]     outside Neovim:
                          start a session with those files

v -n NAME [file ...]      start a named session

v -a, --attach            fuzzy-pick a live session and attach

v -j, --jump              fuzzy-pick a live session
                          or an unopened Git project

v -l, --list              list live sessions

v -k, --kill              fuzzy-pick and force-kill a session

v --load 'pattern' [-n name] [dir]
                          start a session with matching files pre-loaded
```

# Basic workflow

Start a named session:

```sh
cd ~/code/my-project
v -n my-project
```

From another terminal:

```sh
v -a
```

Choose the session with `fzf`.

To see running sessions:

```sh
v -l
```

To find either a running session or a Git project:

```sh
v -j
```

To kill a session:

```sh
v -k
```

Save your work before using `v -k`.

# Named sessions

Use:

```sh
v -n NAME
```

to give a session a predictable identity.

For example:

```sh
v -n project
```

will create a socket based on:

```text
project.sock
```

inside the `v` socket directory.

Naming provides two useful things:

1. `v -l` can show a human-readable name.
2. Starting the same name again can fail instead of silently creating another session with the same conceptual purpose.

Unnamed sessions use a generated socket name based on the project directory and process information.

That is useful for temporary work where you do not care about giving the session a permanent identity.

## Known limitation

Currently:

```sh
v -a -n project
```

does not attach directly to `project`.

The name is ignored for attach mode.

Use:

```sh
v -a
```

and select the session with `fzf`.

Or:

```sh
v -j
```

if you want to select from both live sessions and unopened projects.

# `v -j`

`v -j` is the main navigation command.

It can present:

```text
running Neovim sessions
```

and:

```text
Git projects that have not been opened yet
```

in the same fuzzy workflow.

Conceptually:

```text
                    v -j
                      |
             +--------+--------+
             |                 |
       live sessions       Git projects
             |                 |
             +--------+--------+
                      |
                     fzf
                      |
                      v
                chosen target
```

If you choose a live session, `v` attaches to it.

If you choose an unopened project, `v` starts a new session there.

The point is to make the distinction between:

> "I need to open this project."

and:

> "I need to return to this project."

less important.

# `--load`

`--load` starts a new session and pre-loads files matching a glob.

For example:

```sh
v --load '*.go' -n project ~/code/project
```

or:

```sh
v --load '**/*.c' -n c-project ~/code/c-project
```

Internally this uses `find`.

It skips `.git` and limits the result to 40 files.

This is useful when you want to immediately load the files relevant to a particular language or part of a project.

# Directory and file arguments

`v` treats directories deliberately.

## One directory

When creating a new session, one directory means:

> Start Neovim with this directory as its working directory.

For example:

```sh
v ~/code/project
```

The directory becomes the session's working directory.

This prevents a directory argument from accidentally becoming a netrw buffer.

## Multiple directories

Multiple directory arguments are rejected.

For example:

```sh
v project1/ project2/
```

is an error.

This is intentional.

There is no useful interpretation of multiple directories for the simple session model, and rejecting them avoids accidental netrw behavior.

## Files

Files are resolved with `realpath` and opened.

For example:

```sh
v main.go server.go
```

opens both files.

# Using `v` inside Neovim

This is one of the more useful details of the design.

Imagine:

```text
Neovim
  |
  +-- :terminal
        |
        +-- shell
              |
              +-- v main.go
```

Without special handling, running `v` could start another Neovim inside the terminal:

```text
Neovim
  |
  +-- terminal
        |
        +-- shell
              |
              +-- Neovim
```

That is not what we want.

Instead, `v` detects that the shell belongs to an existing Neovim terminal and sends the file to the parent editor.

Conceptually:

```text
v main.go
    |
    v
parent Neovim
    |
    v
open main.go
```

So the same command:

```sh
v file.py
```

can mean:

```text
outside Neovim
    -> start/open a Neovim session

inside :terminal
    -> tell the existing Neovim to open the file
```

This makes `v` behave like a normal command rather than requiring you to remember whether you are currently inside or outside the editor.

# Why `fzf` matters

`fzf` is not just being used as a nicer menu.

It is part of the reason this workflow works.

The editor already has powerful navigation primitives:

```text
Vim motions
buffers
windows
LSP
grep
marks
search
```

`fzf` provides a fast way to select large sets of things.

Together they create a useful pattern:

```text
generate candidates
       |
       v
      fzf
       |
       v
choose one
       |
       v
continue in Neovim
```

For example:

```text
files
  -> fzf
  -> buffer
```

```text
grep results
  -> fzf
  -> exact line
```

```text
buffers
  -> fzf
  -> existing buffer
```

```text
sessions
  -> fzf
  -> remote Neovim
```

This is why the project is not simply "a way to launch Neovim."

The purpose is to make **Neovim the persistent workspace**, while using small Unix tools to handle selection and discovery.

# fzf navigation

The `v` pickers use normal `fzf`.

These commands use a picker:

```text
v -a
v -j
v -l
v -k
```

By default, fzf uses:

```text
Ctrl-n   down
Ctrl-p   up
```

Bare `j` and `k` remain available for typing into the query field.

If Vim-style movement is preferred, configure fzf once in your shell:

```sh
export FZF_DEFAULT_OPTS='
  --bind=ctrl-j:down,ctrl-k:up
  --bind=ctrl-d:half-page-down,ctrl-u:half-page-up
  --bind=ctrl-f:page-down,ctrl-b:page-up
  --bind=/:show-preview
'
```

All `v` pickers inherit this configuration.

# Do / Don't

| Situation                    | Do                                                                 | Don't                                                     |
| ---------------------------- | ------------------------------------------------------------------ | --------------------------------------------------------- |
| Keep a session alive         | `setsid ... & disown`, park the terminal, or use a service manager | Assume closing the launching terminal leaves Neovim alive |
| Leave an attached session    | Close the `--remote-ui` client                                     | Use `:q` as a detach command                              |
| End a session                | Save, then use `v -k`                                              | Expect `v -k` to provide a save prompt                    |
| Reconnect                    | Use `v -a` or `v -j`                                               | Assume `v -a -n NAME` attaches by name                    |
| Open a file from `:terminal` | Use `v file.py`                                                    | Start another nested Neovim                               |
| Set a working directory      | Pass one directory when creating a session                         | Pass multiple directories                                 |
| Find projects                | Configure `PROJECT_ROOTS` and use `v -j`                           | Put personal project names into the README                |

# Killing a session

`v -k` is deliberately destructive.

It sends:

```vim
<Esc>:qa!<CR>
```

to the selected Neovim process.

That means unsaved changes are discarded.

The intended sequence is:

```text
save
  |
  v
v -k
```

Think of `v -k` as:

> I have decided that this Neovim process should exit.

It is not a terminal detach operation.

# Debugging

Every Neovim instance launched by `v` receives:

```sh
--startuptime /tmp/nvimstartup
```

If startup feels slow:

```sh
cat /tmp/nvimstartup
```

Neovim will show its startup timing information.

The file is shared, so starting another instance can replace the previous startup profile.

## Processes

If a session behaves strangely, inspect the actual process tree:

```sh
pstree -ap
```

The first question should be:

> Is the Neovim process actually alive?

Remember:

```text
session = Neovim process
socket  = address to that process
```

Do not start debugging by assuming the socket is the session.

## Sockets

Inspect Unix sockets with:

```sh
ss -lx
```

You are looking for the socket created by Neovim.

Again, a socket filename is not proof that the Neovim process is still healthy.

# Neovim configuration

The Neovim configuration lives in:

```text
~/.config/nvim/init.lua
```

It intentionally does not use a traditional plugin manager.

Neovim's built-in package system is used:

```lua
vim.pack.add({
    { src = "https://github.com/blazkowolf/gruber-darker.nvim", name = "gruber" },
    { src = "https://github.com/ibhagwan/fzf-lua",              name = "fzf-lua" },
})
```

There is no:

```text
lazy.nvim
packer
vim-plug
```

The package lockfile is:

```text
nvim-pack-lock.json
```

The point is to keep the configuration close to Neovim itself and avoid another layer of infrastructure just to manage a small number of plugins.

# LSP

LSP uses Neovim's built-in interfaces:

```lua
vim.lsp.config
vim.lsp.enable
```

There is no `nvim-lspconfig` dependency.

The configuration is prepared for:

```text
gopls
templ
```

Inlay hints are enabled automatically when an LSP attaches.

Signature help is mapped to:

```text
Ctrl-k
```

in insert mode.

# Terminal working directory

The terminal configuration listens for OSC 7 directory updates.

The basic idea is:

```text
shell changes directory
        |
        v
shell emits OSC 7
        |
        v
Neovim receives the directory
        |
        v
editor follows the shell
```

This keeps the editor's working directory synchronized with the shell running inside its terminal.

# Keymaps

Leader is:

```text
Space
```

Current mappings:

```text
<leader>w       save
<leader>q       quit

<leader>f       fzf files
<leader>b       fzf buffers
<leader>g       live grep
<leader>/       grep current buffer

<leader>sd      LSP document symbols
<leader>sw      LSP workspace symbols
<leader>sr      LSP references

]b / [b         next / previous buffer

<leader>x       close buffer without closing the window

<leader>j / k   move current line down / up
J / K (visual)  move selection down / up

<Esc><Esc>      exit terminal mode

<C-k> (insert)  LSP signature help
```

# Shell helpers

Two optional Bash helpers can be added to `.bashrc`:

```text
vf
vg
```

They are convenience functions built on top of `v`.

They are not required by the session manager.

## `vf` file picker

```sh
vf() {
    local root="${1:-.}"
    local file

    file=$(find "$root" -type f -not -path '*/.git/*' \
        | fzf --preview 'cat {}') || return

    [ -n "$file" ] || return

    v "$file"
}
```

Usage:

```sh
vf
```

or:

```sh
vf ~/code
```

The flow is:

```text
find
  |
  v
fzf
  |
  v
chosen file
  |
  v
v file
  |
  v
Neovim
```

If the command is run from a Neovim terminal, `v` routes the file to the parent Neovim instead of starting a nested editor.

## `vg` grep picker

```sh
vg() {
    local pattern="${1:-}" root="${2:-.}"
    local picked file line

    if command -v rg &>/dev/null; then
        picked=$(rg --color=never --line-number --no-heading "$pattern" "$root" \
            | fzf --delimiter=':' \
                --preview 'bat --style=plain --color=always {1} 2>/dev/null || cat {1}') \
            || return
    else
        picked=$(grep -rn "$pattern" "$root" \
            | fzf --delimiter=':') || return
    fi

    [ -n "$picked" ] || return

    file=$(cut -d: -f1 <<< "$picked")
    line=$(cut -d: -f2 <<< "$picked")

    v +"$line" "$file"
}
```

Usage:

```sh
vg "TODO"
```

or:

```sh
vg "ListenAndServe" ~/code
```

The flow is:

```text
rg / grep
     |
     v
matching lines
     |
     v
fzf
     |
     v
chosen match
     |
     v
file + line number
     |
     v
v +LINE file
     |
     v
Neovim
```

`rg` is preferred when available.

`grep` is the fallback.

`bat` is only used for the preview.

# The design in one picture

The whole system can be reduced to this:

```text
                         v
                         |
              +----------+----------+
              |                     |
          start nvim             find nvim
              |                     |
              v                     v
           --listen               fzf
              |                     |
              v                     v
        Unix socket          chosen socket
              |                     |
              +----------+----------+
                         |
                         v
                  existing Neovim
                         |
          +--------------+--------------+
          |              |              |
       buffers          LSP           terminal
          |              |              |
         fzf           motions        shell
          |              |
          +------+-------+
                 |
                 v
              workflow
```

The important thing is that `v` does not try to own all of this.

It connects existing tools.

```text
Bash
  +
Neovim
  +
Unix sockets
  +
fzf
  +
standard Unix process tools
```

Each tool does one thing.

`v` is the glue.

# Short version

If you forget everything else, remember these:

```text
1. v is a Bash script.

2. The Neovim process is the session.

3. The Unix socket is only the address used to reach that process.

4. --remote-ui connects another terminal to the existing Neovim process.

5. Closing a remote UI is not the same thing as :qa.

6. If the original Neovim process dies, the session dies.

7. fzf provides fast selection and discovery.

8. Vim motions, buffers, LSP, grep, and terminal support remain inside Neovim.

9. v exists to make Neovim itself the persistent workspace, not to recreate tmux.

10. There is no daemon to maintain.
```

The entire design can therefore be summarized as:

```text
                 Neovim
              THE WORKSPACE
                    |
       +------------+------------+
       |            |            |
     buffers       LSP        terminal
       |            |            |
      fzf         motions       shell
       |
    sessions
       |
       v
       v
```

The less infrastructure this needs, the better.

That is the point of `v`.
