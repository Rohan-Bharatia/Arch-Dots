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

    mkdir -p "$dest"
    cp -r "$src/"* "$dest/" 2>/dev/null
}

copy hypr
copy kitty
copy wofi
copy quickshell
copy bash "$HOME"
copy assets "$HOME/Pictures"

# source ~/.bashrc
