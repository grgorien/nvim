# Neovim and TMUX configurations for Fedora 40\Debian\macOS

## Getting started 

### Prerequisites
1. **install Neovim**:
```bash
sudo dnf install neovim
```
### Clone the repository
1. **git clone:**
```bash
git clone https://github.com/williamgregorio/nvim.git ~/.config/
```

## Open nvim
- Lazy should do the work.

## Then install tmux
- e.g (sudo dnf install tmux).

## Source .tmux.conf
- Open tmux e.g (tmux new -s conf) 
- Source by (Ctrl + b) + : -> enter [`source-file ~/.config/nvim/.tmux.conf`] OR replc `source-file` FOR `source`.

## git clone tpm on ~/ OR $HOME
- git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

## Change _get_user_tmux_conf() -> default_location from helpers directory to new directory
- default_location="$HOME/`.config/nvim/`.tmux.conf"

## Apply new installation on tpm
- (Ctrl + a) + Shift + I = Install

### Now enjoy
