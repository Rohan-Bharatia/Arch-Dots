#!/bin/bash

function copy()
{
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

copy hblock "/etc/systemd/system"
copy hypr
copy kitty
copy wofi
copy quickshell
copy bash "$HOME"
copy assets "$HOME/Pictures"

sudo systemctl daemon-reload
sudo systemctl enable --now hblock-update.timer

source ~/.bashrc
