# Neovim and TMUX configurations for Fedora 40\Debian\macOS

## Getting started 

### Prerequisites
1. **install Neovim**:
```bash
sudo dnf install neovim
```
2. **install tmux**:
```bash
sudo dnf install tmux
```

### Clone this repository
1. **git clone:**
```bash
git clone https://github.com/williamgregorio/nvim.git ~/.config/
```

### Clone the Tmux Plugin Manager (TPM) repository
1. **add this to your $HOME**:
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm ~/
```
2. **Link the TMUX configuration file**:
```bash
ln -s ~/.config/nvim/.tmux.conf ~/.tmux.conf
```
### Source the .tmux.conf file
1. **Open Tmux** (e.g. `tmux new -s conf`)
2. **Source the configuration**:
- Press `Ctrl + b`, then `:` to enter command mode, and type:
```bash
source-file ~/.tmux.conf
```
`OR`
```bash
source ~/.tmux.conf
```
### Confirm the installation of TPM
1. **install plugins with TPM,** press:
- `Ctrl + a`, then `Shift + I` (this is my preffered binding; adjust freely.)

### Now enjoy
