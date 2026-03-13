#!/bin/bash

function copy() {
    if [ -z "$1" ]; then
        echo "Usage: copy <source_folder_name> [destination]"
        return 1
    fi

    src="$1"
    dest="$2"

    if [ -z "$dest" ]; then
        dest="$HOME/.config/$src"
    fi

    if [[ "$dest" == /etc/* || "$dest" == /usr/* ]]; then
        sudo mkdir -p "$dest"
        sudo cp -a "$src"/. "$dest"/ --remove-destination
    else
        mkdir -p "$dest"
        cp -a "$src"/. "$dest"/ --remove-destination
    fi
}

sudo chown -R $USER:$USER "$HOME/Pictures"

copy applications "/usr/share/applications"
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
copy qt5ct
copy qt6ct
copy rofi
copy service "/etc/systemd/system"
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

sudo find "$HOME/.user_scripts" -type f -name "*.sh" -exec chmod +x {} \;

sudo systemctl daemon-reload
sudo systemctl enable --now hblock-update.timer
sudo systemctl start ollama
sudo ln -nfs /usr/lib/ollama /usr/local/lib/ollama
sudo systemctl enable --now swayosd-libinput-backend.service

git config --global credential.helper /usr/lib/git-core/git-credential-libsecret

source ~/.zshrc
