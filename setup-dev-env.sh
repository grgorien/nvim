#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TOOLS_DIR="$HOME/.local/tools"
BIN_DIR="$HOME/.local/bin"
NVIM_CONFIG_DIR="$HOME/.config/nvim"

mkdir -p "$TOOLS_DIR" "$BIN_DIR"

print_status() { echo -e "${BLUE}==>${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}!${NC} $1"; }

check_command() {
    command -v "$1" &> /dev/null
}

confirm_install() {
    local tool=$1
    echo -n -e "${YELLOW}$tool not installed. Would you like to install it? (y/n):${NC} "
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

add_to_path() {
    local path_to_add="$1"
    local shell_rc="$HOME/.bashrc"
    [ -n "$ZSH_VERSION" ] && shell_rc="$HOME/.zshrc"
    
    if ! grep -q "$path_to_add" "$shell_rc" 2>/dev/null; then
        echo "export PATH=\"$path_to_add:\$PATH\"" >> "$shell_rc"
        export PATH="$path_to_add:$PATH"
    fi
}

install_system_deps() {
    print_status "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    
    print_status "Installing build dependencies..."
    sudo apt install -y build-essential git curl wget unzip \
        ninja-build gettext cmake bison libreadline-dev \
        pkg-config libtool autoconf automake \
        libevent-dev libncurses-dev
    
    print_success "System dependencies installed"
}

build_from_git() {
    local name=$1
    local repo_url=$2
    local build_dir=$3
    local install_to_bin=${4:-false}
    
    print_status "Installing $name from source..."
    
    cd "$TOOLS_DIR"
    if [ -d "$build_dir" ]; then
        print_warning "$name directory exists, updating..."
        cd "$build_dir"
        git fetch --tags
    else
        git clone "$repo_url" "$build_dir"
        cd "$build_dir"
    fi
    
    local latest_tag=$(git tag -l --sort=-v:refname | grep -v 'rc\|alpha\|beta' | head -n1)
    if [ -z "$latest_tag" ]; then
        latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "main")
    fi
    
    print_status "Checking out: $latest_tag"
    git checkout "$latest_tag" 2>/dev/null || git checkout main
    
    if [ -f "autogen.sh" ]; then
        sh autogen.sh
    fi
    
    ./configure
    make -j$(nproc)
    sudo make install
    
    if [ "$install_to_bin" = true ] && [ -f "bin/$name" ]; then
        ln -sf "$TOOLS_DIR/$build_dir/bin/$name" "$BIN_DIR/$name"
    fi
    
    print_success "$name installed"
}

install_neovim() {
    if check_command nvim; then
        local version=$(nvim --version | head -n1)
        print_warning "Neovim already installed: $version"
        if ! confirm_install "Neovim"; then
            return 0
        fi
    fi
    
    build_from_git "neovim" "https://github.com/neovim/neovim.git" "neovim"
    
    if check_command nvim; then
        print_success "Neovim $(nvim --version | head -n1 | awk '{print $2}')"
    fi
}

install_tmux() {
    if check_command tmux; then
        local version=$(tmux -V | cut -d' ' -f2)
        print_warning "tmux already installed: $version"
        if ! confirm_install "tmux"; then
            return 0
        fi
    fi
    
    build_from_git "tmux" "https://github.com/tmux/tmux.git" "tmux"
    
    if check_command tmux; then
        print_success "tmux $(tmux -V)"
        
        if [ -f "$NVIM_CONFIG_DIR/configure-tmux.sh" ]; then
            print_status "Running tmux configuration script..."
            bash "$NVIM_CONFIG_DIR/configure-tmux.sh"
        else
            print_warning "tmux config script not found at $NVIM_CONFIG_DIR/configure-tmux.sh"
        fi
    fi
}

install_lua_ls() {
    if [ -f "$BIN_DIR/lua-language-server" ]; then
        print_warning "lua-language-server already installed"
        if ! confirm_install "lua-language-server"; then
            return 0
        fi
    fi
    
    print_status "Installing Lua Language Server..."
    
    cd "$TOOLS_DIR"
    if [ -d "lua-language-server" ]; then
        cd lua-language-server
        git fetch --tags
    else
        git clone https://github.com/LuaLS/lua-language-server.git
        cd lua-language-server
    fi
    
    local latest_tag=$(git describe --tags --abbrev=0)
    print_status "Checking out: $latest_tag"
    git checkout "$latest_tag"
    
    git submodule update --init --recursive
    cd 3rd/luamake
    ./compile/install.sh
    cd ../..
    ./3rd/luamake/luamake rebuild
    
    ln -sf "$TOOLS_DIR/lua-language-server/bin/lua-language-server" "$BIN_DIR/lua-language-server"
    
    print_success "Lua Language Server installed"
}

install_go() {
    if check_command go; then
        local version=$(go version | awk '{print $3}')
        print_warning "Go already installed: $version"
        if ! confirm_install "Go"; then
            return 0
        fi
    fi
    
    print_status "Installing Go..."
    
    local go_version=$(curl -s https://go.dev/VERSION?m=text | head -n1)
    local go_archive="${go_version}.linux-amd64.tar.gz"
    
    cd /tmp
    wget -q "https://go.dev/dl/$go_archive"
    rm -rf "$TOOLS_DIR/go"
    tar -xzf "$go_archive" -C "$TOOLS_DIR"
    rm "$go_archive"
    
    add_to_path "$TOOLS_DIR/go/bin"
    add_to_path "$HOME/go/bin"
    export PATH="$TOOLS_DIR/go/bin:$HOME/go/bin:$PATH"
    
    print_success "Go $go_version installed"
}

install_nvm_node() {
    if [ -d "$HOME/.nvm" ]; then
        print_warning "NVM already installed"
        if ! confirm_install "NVM"; then
            return 0
        fi
    fi
    
    print_status "Installing NVM..."
    
    cd "$TOOLS_DIR"
    git clone https://github.com/nvm-sh/nvm.git "$HOME/.nvm"
    cd "$HOME/.nvm"
    git checkout $(git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1))
    
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    local shell_rc="$HOME/.bashrc"
    [ -n "$ZSH_VERSION" ] && shell_rc="$HOME/.zshrc"
    
    if ! grep -q "NVM_DIR" "$shell_rc" 2>/dev/null; then
        cat >> "$shell_rc" << 'NVMEOF'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
NVMEOF
    fi
    
    print_status "Installing Node.js LTS..."
    nvm install --lts
    nvm use --lts
    nvm alias default lts/*
    
    print_success "NVM and Node.js LTS installed"
}

install_node_language_servers() {
    print_status "Installing Node.js language servers..."
    
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    local packages=(
        "vscode-langservers-extracted"
        "typescript"
        "typescript-language-server"
        "@shopify/cli"
        "@tailwindcss/language-server"
    )
    
    for pkg in "${packages[@]}"; do
        print_status "Installing $pkg..."
        npm install -g "$pkg"
    done
    
    print_success "Node.js language servers installed"
}

install_rust() {
    if check_command rustc; then
        local version=$(rustc --version | awk '{print $2}')
        print_warning "Rust already installed: $version"
        if ! confirm_install "Rust"; then
            return 0
        fi
        rustup update stable
    else
        print_status "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
        source "$HOME/.cargo/env"
    fi
    
    add_to_path "$HOME/.cargo/bin"
    export PATH="$HOME/.cargo/bin:$PATH"
    
    rustup component add rust-analyzer
    
    print_success "Rust installed"
}

verify_installation() {
    print_status "Verifying installations..."
    
    local tools=(
        "nvim:Neovim"
        "tmux:tmux"
        "lua-language-server:Lua LS"
        "go:Go"
        "node:Node.js"
        "npm:npm"
        "rustc:Rust"
    )
    
    for tool_pair in "${tools[@]}"; do
        IFS=':' read -r cmd name <<< "$tool_pair"
        if check_command "$cmd"; then
            print_success "$name"
        else
            print_error "$name not found"
        fi
    done
    
    echo ""
    print_success "Setup complete!"
    print_warning "Run 'source ~/.bashrc', 'source ~/.profile'  or restart your terminal"
}

main() {
    echo ""
    echo "=========================================="
    echo "  Portable Dev Environment Setup"
    echo "=========================================="
    echo ""
    
    install_system_deps
    echo ""
    
    install_neovim
    echo ""
    
    install_tmux
    echo ""
    
    install_lua_ls
    echo ""
    
    install_go
    echo ""
    
    install_nvm_node
    echo ""
    
    install_node_language_servers
    echo ""
    
    install_rust
    echo ""
    
    verify_installation
}

main
