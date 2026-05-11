#!/usr/bin/env sh

set -e

PACMAN_PKG_LIST=(base-devel git gcc hyprland hypridle swappy gtk3 gtk4 qt5ct qt6ct swaync swayosd \
                 pavucontrol rclone python python-pip ttf-dejavu fastfetch openresolv fzf \
                 nvim matugen uwsm cava fontconfig xsettingsd yazi zathura cpio brightnessctl \
                 nodejs npm xorg-xhost gnome-keyring libsecret starship vlc mpv libva-utils \
                 unzip rustup uv clang ffmpeg wl-clipboard mbuffer less discord libpulse zsh \
                 zsh-completions zsh-syntax-highlighting seahorse networkmanager \
                 network-manager-applet blender kicad chromium eza expac polkit-gnome trash-cli)
YAY_PKG_LIST=(nerd-fonts spotify spicetify zen-browser-bin cloudflare-warp-bin)

sudo pacman -Syu --needed --noconfirm "${PACMAN_PKG_LIST[@]}"

if ! command -v yay &>/dev/null 1>&2; then
    mkdir -p $HOME/tmp
    cd $HOME/tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd $HOME
fi

yay -Syu --needed --noconfirm "${YAY_PKG_LIST[@]}"

hyprpm update
hyprpm add https://github.com/hyprwm/hyprland-plugins
hyprpm add https://github.com/virtcode/hypr-dynamic-cursors
hyprpm add https://github.com/hyprnux/hyprglass
hyprpm enable hyprexpo
hyprpm enable hyprtrails
hyprpm enable dynamic-cursors
hyprpm enable hyprglass
hyprpm reload
hyprctl reload

rustup default stable

ollama serve
sudo useradd -r -s /bin/false -U -m -d /usr/share/ollama ollama
sudo usermod -a -G ollama $(whoami)

REAPER_URL="https://www.reaper.fm/files/7.x/reaper769_linux_x86_64.tar.xz"
REAPER_TAR="$HOME/reaper769_linux_x86_64.tar.xz"
REAPER_DIR="$HOME/reaper769_linux_x86_64"
curl -L "$REAPER_URL" -o "$REAPER_TAR"
tar -xzf "$REAPER_TAR"
chmod +x ./"$REAPER_DIR"/install-reaper.sh
./"$REAPER_DIR"/install-reaper.sh
rm -rf "$REAPER_TAR" "$REAPER_DIR"
