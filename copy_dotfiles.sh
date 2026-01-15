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

copy matugen
copy hblock "/etc/systemd/system"
copy hypr
copy uwsm
copy waypaper
copy kitty
copy rofi
copy waybar
copy nvim
copy swaync
copy swayosd
copy fastfetch
copy xsettingsd
copy yazi
copy zathura
copy autostart
copy bash "$HOME"
copy assets "$HOME/Pictures"
copy scripts "$HOME/.user_scripts"

sudo systemctl daemon-reload
sudo systemctl enable --now hblock-update.timer

source ~/.bashrc
