#!/bin/bash

if [[ "${EUID}" -ne 0 ]]; then
    echo "This script requires root privileges. Elevating..."
    exec sudo "$0" "$@"
fi

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
    cp -r "$src/*" "$dest/"
}

copy assets "$HOME/Pictures"
copy autostart
copy btop
copy cava
copy fastfetch
copy fontconfig
copy gtk-3.0
copy gtk-4.0
copy hypr
copy kitty
copy matugen
copy xdg "$HOME/.config"
copy nvim
copy pam "/etc/pam.d"
copy qt5ct
copy qt6ct
copy rofi
copy service "/etc/systemd/service"
copy scripts "$HOME/.user_scripts"
copy starship "$HOME/.config"
copy swaync
copy swayosd
copy systemd
copy uwsm
copy waybar
copy waypaper
copy wlogout
copy xsettingsd
copy yazi
copy zathura
copy zsh "$HOME"

sudo chmod +x $HOME/.user_scripts/**/*.sh

sudo systemctl daemon-reload
sudo systemctl enable --now hblock-update.timer
sudo systemctl start ollama
sudo ln -nfs /usr/lib/ollama /usr/local/lib/ollama

git config --global credential.helper /usr/lib/git-core/git-credential-libsecret

source ~/.zshrc
