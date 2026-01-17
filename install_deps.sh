#!/bin/bash

set -euo pipefail

cd $HOME

sudo pacman -Syu
sudo pacman -S --noconfirm base-devel gcc hyprland hyprpaper hyprlock hypridle hyprshot hyprsunset waybar kitty rofi nemo btop pipewire playerctl gtk3 git pavucontrol rclone spotify-launcher python python-pip ttf-dejavu fastfetch openresolv fzf nvim matugen uwsm cava fontconfig swaync swayosd xsettingsd yazi zathura cmake meson cpio swww brightnessctl yad gnome-clocks nodejs npm imagemagick

hyprpm update
hyprpm add https://github.com/hyprwm/hyprland-plugins
hyprpm enable hyprexpo

if ! command -v yay >/dev/null; then
    mkdir -p $HOME/tmp
    cd $HOME/tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd $HOME
fi

yay -S nerd-fonts blueman zen-browser-bin hblock waypaper wifitui hyprshade tray-tui

if ! command -v ollama >/dev/null; then
    cd $HOME
    curl -fsSL https://ollama.com/install.sh | sh
fi

ollama pull phi3:mini
rclone config

for "$arg" in "$@"; do
    case "$arg" in
        --wpilib)
            local url="https://packages.wpilib.workers.dev/installer/v2025.3.2/Linux/WPILib_Linux-2025.3.2.tar.gz"
	    local tar="$HOME/WPILib_Linux-2025.3.2.tar.gz"
	    local dir="$HOME/WPILib_Linux-2025.3.2"
	    curl -L "$url" -o "$tar"
	    tar -xzf "$tar"
	    cd "$dir"
	    ./WPILibInstaller
	    cd "$HOME"
            ;;
        *)
            ;;
    esac
done
