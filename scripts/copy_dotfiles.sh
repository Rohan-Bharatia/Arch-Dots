#!/usr/bin/env sh

set -e

copy_safe() {
    src="$1"
    dest="$2"
    if [ -d "$src" ]; then
        mkdir -p "$dest"
        cp -rf "$src"/. "$dest"/
    else
        cp -f "$src" "$dest"
    fi
}

copy_safe "./.config" "$HOME/.config"
copy_safe "./.local" "$HOME/.local"
copy_safe "./Desktop" "$HOME/Desktop"
copy_safe "./.zshrc" "$HOME/.zshrc"

if [ -d "$HOME/.local/scripts" ]; then
    sudo find $HOME/.local/scripts -type f -name '*.sh' -exec chmod +x {} \;
fi

if [ -n "$ZSH_VERSION" ]; then
    source $HOME/.zshrc
fi
