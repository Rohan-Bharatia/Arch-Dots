#!/bin/bash

function copy() {
    if [ -z "$1" ]; then
        echo "Usage: copy <source_folder_name>"
        return 1
    fi

    src="$1"
    dest="$2"

    if [ -z "$2" ]; then
        dest="$HOME/.config/$src"
    fi

    sudo mkdir -p "$dest"
    sudo cp -r "$src/." "$dest/" 2>/dev/null
}

copy assets "$HOME/Pictures"
copy autostart
copy bash "$HOME"
copy btop
copy cava
copy fastfetch
copy fontconfig
copy gtk-3.0
copy gtk-4.0
copy hblock "/etc/systemd/system"
copy hypr
copy kitty
copy matugen
copy nvim
copy qt5ct
copy qt6ct
copy rofi
copy scripts "$HOME/.user_scripts"
copy swaync
copy swayosd
copy systemd
copy uwsm
copy waybar
copy waypaper
copy xsettingsd
copy yazi
copy zathura

sudo systemctl daemon-reload
sudo systemctl enable --now hblock-update.timer

source ~/.bashrc
