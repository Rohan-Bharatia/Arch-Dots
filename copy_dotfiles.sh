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
copy tor "/etc/tor"
copy hypr
copy kitty
copy wofi
copy quickshell
copy bash "$HOME"
copy assets "$HOME/Pictures"

# A manual wireguard configuration install is required for security reasons
sudo wg-quick up /etc/wireguard/mullvad.conf 2>/dev/null
sudo systemctl enable --now tor.service

sudo iptables -t nat -A OUTPUT -m owner --uid-owner $USER -d 127.0.0.1/8 -j RETURN
sudo iptables -t nat -A OUTPUT -m owner --uid-owner $USER -d 192.168.0.0/16 -j RETURN
sudo iptables -t nat -A OUTPUT -p tcp -m owner --uid-owner $USER -j REDIRECT --to-ports 9050

sudo systemctl daemon-reload
sudo systemctl enable --now hblock-update.timer

source ~/.bashrc
