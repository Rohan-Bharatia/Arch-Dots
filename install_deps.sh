#!/bin/bash

set -euo pipefail

cd $HOME

sudo pacman -Syu
sudo pacman -S --noconfirm gcc hyprland hyprpaper hyprlock hypridle hyprshot hyprsunset kitty wofi nemo btop pipewire playerctl gtk3 git pavucontrol rclone spotify-launcher python ttf-dejavu fastfetch

if ! command -v yay >/dev/null; then
    mkdir -p $HOME/tmp
    cd $HOME/tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd $HOME
fi

yay -S dunst quickshell nerd-fonts blueman zen-browser-bin

if ! command -v ollama >/dev/null; then
    cd $HOME
    curl -fsSL https://ollama.com/install.sh | sh
fi

ollama pull phi3:mini
rclone config

if [ "$1" == "--install-wpilib" ]; then
    sudo ./install_wpilib.sh
fi
