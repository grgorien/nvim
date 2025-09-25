#!/bin/bash

# configure-tmux.sh: Sets up tmux by linking config and installing plugins

set -e

NVIM_CONFIG_DIR="$HOME/.config/nvim"
TMUX_CONF_SRC="$NVIM_CONFIG_DIR/tmux.conf"
TMUX_CONF_DEST="$HOME/.tmux.conf"
TPM_DIR="$HOME/.tmux/plugins/tpm"

# check if tmux is installed
if ! command -v tmux >/dev/null 2>&1; then
    echo "tmux not found. Please install tmux first (e.g., 'sudo apt install tmux' or build from source)."
    echo "To build from source, run:"
    echo "  sudo apt install build-essential libevent-dev libncurses-dev autoconf automake pkg-config bison"
    echo "  git clone https://github.com/tmux/tmux.git ~/.config/tmux"
    echo "  cd ~/.config/tmux"
    echo "  git checkout 3.5"
    echo "  sh autogen.sh"
    echo "  ./configure"
    echo "  make"
    echo "  sudo make install"
    exit 1
fi

# check tmux version
TMUX_VERSION=$(tmux -V | cut -d' ' -f2)
echo "Found tmux version: $TMUX_VERSION"

# Check if tmux.conf exists in Neovim config
if [ ! -f "$TMUX_CONF_SRC" ]; then
    echo "Error: $TMUX_CONF_SRC not found. Please ensure tmux.conf is in $NVIM_CONFIG_DIR."
    exit 1
fi

# create symbolic link to ~/.tmux.conf
if [ -f "$TMUX_CONF_DEST" ] || [ -L "$TMUX_CONF_DEST" ]; then
    echo "Backing up existing $TMUX_CONF_DEST to $TMUX_CONF_DEST.bak"
    mv "$TMUX_CONF_DEST" "$TMUX_CONF_DEST.bak"
fi
echo "Linking $TMUX_CONF_SRC to $TMUX_CONF_DEST"
ln -sf "$TMUX_CONF_SRC" "$TMUX_CONF_DEST"

# install TPM if not already present
if [ ! -d "$TPM_DIR" ]; then
    echo "Installing Tmux Plugin Manager (TPM) to $TPM_DIR"
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    echo "TPM already installed at $TPM_DIR"
fi

# start tmux and install plugins
echo "Starting tmux to install plugins (press C-q I in tmux to install plugins)"
tmux new-session -d -s tmp_setup
tmux source-file "$TMUX_CONF_DEST"
tmux run-shell "$TPM_DIR/scripts/install_plugins.sh"
tmux kill-session -t tmp_setup

echo "tmux setup complete!"
echo "Start tmux with 'tmux' and use C-q as the prefix."
echo "To manually install/update plugins, press C-q I in a tmux session."
